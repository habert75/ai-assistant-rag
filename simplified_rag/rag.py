import os.path
from os import listdir
from dotenv import load_dotenv
from os.path import isfile, join
from typing import Literal, get_args
from langchain_core.documents import Document
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser
from langchain_community.tools import WikipediaQueryRun
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.document_loaders import PyPDFLoader
from langchain_community.utilities import WikipediaAPIWrapper
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import DocArrayInMemorySearch
from langfuse.langchain import CallbackHandler

DataSource = Literal["Wikipedia", "Research Paper"]
SUPPORTED_DATA_SOURCES = get_args(DataSource)

# loading API keys from env
load_dotenv()
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

if OPENAI_API_KEY == 'xxxxxxxx':
    raise ValueError("Please add your own OpenAI API key in the .env file by replacing 'xxxxxxxx' with your own key.")

# Initialize Langfuse CallbackHandler
langfuse_handler = CallbackHandler()

# loading model and defining embedding
llm = ChatOpenAI(temperature=0, model='gpt-3.5-turbo')
embeddings = OpenAIEmbeddings()

# get target folder for uploaded docs
target_folder = "./docs/"

def load_data_set(source: DataSource, query: str):
    if source not in SUPPORTED_DATA_SOURCES:
        raise ValueError(f"Provided data source {source} is not supported.")

    # fragmenting the document content to fit in the number of token limitations
    text_splitter = RecursiveCharacterTextSplitter(chunk_size = 500, chunk_overlap = 50)

    if source == "Wikipedia":
        Wikipedia = WikipediaQueryRun(api_wrapper=WikipediaAPIWrapper())
        data = Wikipedia.run(query)
        split_docs = [Document(page_content=sent) for sent in data.split('\n')]
    else:
        # get files from target directory
        my_file = [f for f in listdir(target_folder) if isfile(join(target_folder, f))]
        my_file = target_folder + my_file[0]
        print(f"my file is {my_file}")

        # load uploaded pdf file
        loader = PyPDFLoader(my_file)
        data = loader.load()
        split_docs = text_splitter.split_documents(data)

    data_set = DocArrayInMemorySearch.from_documents(documents = split_docs, embedding = embeddings)

    return data_set


def retrieve_info(source: DataSource, data_set: DocArrayInMemorySearch, query: str):
    if source not in SUPPORTED_DATA_SOURCES:
        raise ValueError(f"Provided data source {source} is not supported.")

    # Create a RAG prompt template
    template = """Answer the question based only on the following context:
{context}

Question: {question}

Answer:"""
    
    prompt = ChatPromptTemplate.from_template(template)
    
    # Create retriever
    retriever = data_set.as_retriever()
    
    # Format documents function
    def format_docs(docs):
        return "\n\n".join(doc.page_content for doc in docs)
    
    # Create the chain
    rag_chain = (
        {"context": retriever | format_docs, "question": RunnablePassthrough()}
        | prompt
        | llm
        | StrOutputParser()
    )
    
    # Invoke the chain with Langfuse callback
    output = rag_chain.invoke(query, config={"callbacks": [langfuse_handler]})
    
    return {"result": output, "query": query}


def generate_answer(selection: DataSource, query: str):
    if selection not in SUPPORTED_DATA_SOURCES:
        raise ValueError(f"Provided data source {selection} is not supported.")

    data_set = load_data_set(selection, query)
    response = retrieve_info(selection, data_set, query)
    
    return response
print("hello")
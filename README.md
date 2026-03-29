# AI Assistant RAG Application

A Streamlit-based RAG (Retrieval-Augmented Generation) application that allows users to query information from Wikipedia or uploaded PDF documents using OpenAI's language models.

## Features

- **Wikipedia Search**: Query information directly from Wikipedia
- **PDF Document Analysis**: Upload and query your own PDF documents
- **RAG Implementation**: Uses LangChain for document retrieval and question answering
- **Interactive UI**: Built with Streamlit for easy interaction

## Prerequisites

- Docker (for containerized deployment)
- Python 3.11+ (for local development)
- OpenAI API key

## Setup

### 1. Configure Environment Variables

Create a `.env` file in the project root with your OpenAI API key:

```bash
OPENAI_API_KEY=your_openai_api_key_here
```

**Important**: Replace `your_openai_api_key_here` with your actual OpenAI API key.

## Running with Docker

### Build the Docker Image

```bash
docker build -t ai-assistant-rag .
```

### Run the Container

```bash
docker run -p 8503:8503 --env-file .env ai-assistant-rag
```

Or with inline environment variable:

```bash
docker run -p 8503:8503 -e OPENAI_API_KEY=your_key_here ai-assistant-rag
```

### Access the Application

Open your browser and navigate to:
```
http://localhost:8503
```

## Running Locally (Without Docker)

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the Application

```bash
streamlit run app.py
```

The application will automatically open in your default browser at `http://localhost:8503`.

## Usage

### Wikipedia Query Mode

1. Select **"Wikipedia"** from the dropdown menu
2. Click **"Select"** button
3. Enter your search query in the text input field
4. Click **"Submit"** to get answers from Wikipedia

### Research Paper Mode

1. Select **"Research Paper"** from the dropdown menu
2. Click **"Select"** button
3. Upload a PDF document using the file uploader
4. Enter your question about the document
5. Click **"Load Document"** to process and get answers

## Configuration

The application is configured to run on port **8503** and is accessible from all network interfaces (`0.0.0.0`).

To modify these settings, edit `.streamlit/config.toml`:

```toml
[server]
port = 8503
address = "0.0.0.0"
```

---

## 🚀 Kubernetes & ArgoCD Deployment

For production deployment using Kubernetes and ArgoCD with proper GitOps workflow, see:

📘 **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide with:
- Versioned Docker image workflow
- ArgoCD integration
- Automated deployment script
- Troubleshooting tips

### Quick Deploy

```powershell
# Use the automated deployment script
.\deploy.ps1 -Version v1.0.4 -Message "Your deployment message"
```

**Current Setup:**
- Docker Hub: `habert/ai-assistant-rag`
- GitHub: `https://github.com/habert75/ai-assistant-rag`
- Kubernetes Namespace: `ai-assistant-rag`
- Service URL: http://localhost:8503

## Project Structure

```
ai-assistant-rag/
├── app.py                  # Main Streamlit application
├── simplified_rag/
│   └── rag.py             # RAG implementation logic
├── .streamlit/
│   └── config.toml        # Streamlit configuration
├── docs/                  # Runtime directory for uploaded documents
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration
├── .dockerignore         # Docker ignore patterns
├── .env                  # Environment variables (create this)
└── README.md            # This file
```

## Troubleshooting

### API Key Issues

If you see an error about API keys:
- Ensure your `.env` file exists and contains a valid OpenAI API key
- When using Docker, make sure to pass the environment variables with `--env-file .env` or `-e`

### Port Already in Use

If port 8503 is already in use, you can map to a different port:

```bash
docker run -p 8080:8503 --env-file .env ai-assistant-rag
```

Then access the app at `http://localhost:8080`

## Dependencies

- streamlit - Web application framework
- langchain - LLM application framework
- langchain_openai - OpenAI integration
- langchain_community - Community integrations
- pypdf - PDF file processing
- docarray - Vector storage
- wikipedia - Wikipedia API wrapper
- python-dotenv - Environment variable management

# Ubuntu Elimu: Enterprise-Grade Offline Student Copilot

Ubuntu Elimu is a fully autonomous, local-first educational copilot engineered to bypass the digital divide. By running state-of-the-art quantized Small Language Models (SLMs) natively on consumer edge devices via the **Denizen AI SDK**, it eliminates internet dependency, cellular data costs, and cloud infrastructure latency.

Built directly on top of **Denizen AI Engine**, Ubuntu Elimu turns standard tablets, smartphones, and low-cost computer labs into secure, high-performance, and deeply personalized Socratic educational hubs.

---

## 🚀 Key Features

* **Socratic AI Tutor**: Active Socratic retrieval that guides students step-by-step through curriculum concepts powered by `DenizenSession` streaming and native RAG.
* **Native Offline Vector RAG**: High-precision vector similarity search using `sqlite-vec` C-FFI and local 384-dimensional TFLite embeddings.
* **Document Summarizer**: Token-budgeted Map-Reduce summarization pipeline built to avoid context overflow and Out-of-Memory (OOM) errors on mobile hardware.
* **Exam Prep & Flashcards**: Live AI extraction of key definitions and Q&A flashcards directly from uploaded study material.
* **AI Research Assistant**: Cross-referencing and markdown synthesis between handbooks, uploaded PDFs, and study topics.
* **Personalized Study Planner**: Multi-day study schedules with time allocations synthesized from student library documents.
* **Zero Cloud Dependency**: 100% on-device neural model execution via GGUF format (Llama 3.2, Qwen 2.5).

---

## 🏗️ Technical Architecture & Denizen AI SDK Pipeline

Ubuntu Elimu executes the entire document extraction, embedding, vector storage, and neural generation loop completely offline:

```text
[ Student Uploads: PDF, DOCX, TXT ]
           │
           ▼
[ Local Text Extractor & Token Budget Chunking ]
- Native PDF & DOCX text extraction
- Token-budgeted 150-word chunking with 25-word overlap
           │
           ▼
[ Denizen AI SDK: TFLiteEmbeddingProvider ]
- Local 384-dimensional vector embedding extraction
           │
           ▼
[ Vector Storage Engine: VectorStorageService (sqlite-vec) ]
- Native C-FFI hardware-accelerated vector similarity search
           │
           ▼
[ On-Device GGUF Engine: DenizenAI ]
- DenizenSession / createRagSession token-by-token streaming
- Memory-safe model loading & auto RAM unloading (OOM protected)
```

---

## 🛠️ Tech Stack

* **Core Framework:** [Flutter](https://flutter.dev/) (Dart 3.3+)
* **AI Platform SDK:** [Denizen AI SDK](https://github.com/Ubuntu-Edge/Ubuntu-Elimu) (`denizen_ai`)
* **Inference Engine:** `llama_flutter_android` (C++ llama.cpp GGUF engine bindings)
* **Vector Database:** `sqlite-vec` (Native C FFI vector search)
* **Embeddings:** Local 384-dimensional TFLite Embedding Provider
* **State Management:** Provider / Riverpod
* **Local Storage:** Hive & SharedPreferences

---

## 📦 Getting Started

### Prerequisites
* Flutter SDK (3.22.0+)
* Android NDK & SDK (API level 24+)
* Android device or emulator (Minimum 3GB RAM recommended for 0.5B/1B models)

### Installation & Build

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Ubuntu-Edge/Ubuntu-Elimu.git
   cd Ubuntu-Elimu
   ```

2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

3. **Build Debug APK:**
   ```bash
   flutter build apk --debug
   ```

4. **Build Production Release APK:**
   ```bash
   flutter build apk --release
   ```

---

## 📱 Model Activation & AI Usage

1. Open **Settings** screen inside the app.
2. Tap **Download** on any recommended model (e.g. *Qwen 2.5 0.5B* or *Llama 3.2 1B*).
3. The Denizen AI engine will automatically download, cache, and load the GGUF model into neural RAM.
4. Navigate to **AI Tutor**, **Research**, or **Library Documents** to begin live 100% offline AI inference!

---

## 📄 License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.

# Contributing to Border Safety Alert System (BSAS)

Thank you for your interest in contributing to the **Border Safety Alert System (BSAS)**!

## Code of Conduct
Please maintain a respectful, constructive, and collaborative environment.

## Development Workflow

1. **Fork & Branch**:
   - Clone the repository: `git clone https://github.com/jagetheswaren/Border-Safety-Alert-System.git`
   - Create a feature branch: `git checkout -b feature/your-feature-name`

2. **Mobile (Flutter)**:
   - Ensure Flutter SDK (3.44.4+) is installed.
   - Run analysis: `flutter analyze lib/`
   - Run tests: `flutter test`

3. **Backend (FastAPI)**:
   - Create and activate a virtual environment:
     ```bash
     python -m venv venv
     source venv/bin/activate  # Or .\venv\Scripts\Activate.ps1 on Windows
     pip install -r backend/requirements.txt
     ```
   - Run pytest: `pytest backend/tests -v`

4. **Frontend Dashboard (Next.js)**:
   - Navigate to `frontend/`:
     ```bash
     cd frontend
     npm install
     npm run lint
     npm run build
     ```

5. **Submitting Changes**:
   - Write clear, concise commit messages.
   - Ensure all automated tests pass before opening a Pull Request.
   - Adhere to the established architecture principles: deterministic safety decisions must remain independent from advisory AI layers.

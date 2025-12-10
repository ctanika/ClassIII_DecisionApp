# README — ClassIII_DecisionApp

## Overview

ClassIII_DecisionApp is a MATLAB-based clinical decision support tool designed to assist orthodontists in determining whether camouflage treatment or orthognathic surgery is appropriate for patients with skeletal Class III malocclusion.  
The application integrates:

- MG-Sk3 (Fuzzy membership grade): Soft-tissue–based estimate of skeletal Class III severity  
- Linear combination (LC) model based on cephalometric measurements  
- A rule-based decision tree derived from clinical data  
- Optional ChatGPT summarization of the diagnostic explanation

The program provides a user-friendly GUI for entering cephalometric measurements and displays the predicted treatment recommendation together with an interpretable explanation.

## Features

- Input seven cephalometric values: ANB, Gn–Nperp, SN, Go–Me, Overjet, Me–PP, H-angle
- Automatic computation of:
  - Linear Combination (LC)
  - MG-Sk3 (fuzzy estimate)
  - Final treatment decision (Camouflage / Surgery)
- Rule-based generation of a diagnostic explanation
- Optional ChatGPT mode using OpenAI API
- Standalone executable available (no MATLAB installation required)

## How to Run (Standalone Version)

1. Download the packaged installer (`ClassIII_DecisionApp.exe`).
2. Run the installer and follow on-screen instructions to install the MATLAB Runtime (if prompted).
3. Launch ClassIII_DecisionApp from your desktop/start menu.

MATLAB Runtime is automatically installed on first use if not already present.

## How to Run (MATLAB Source Code)

If you prefer to run the `.m` version directly:

1. Ensure MATLAB R2022a or later is installed.
2. Clone or download this repository.
3. Add the folder to your MATLAB path.
4. Run:

```
app = ClassIII_DecisionApp;
```

## ChatGPT Integration (Optional)

To enable ChatGPT-based summarization:

### Windows (PowerShell)

```
setx OPENAI_API_KEY "your_api_key_here"
```

### macOS / Linux

```
export OPENAI_API_KEY="your_api_key_here"
```

Then set ChatGPT Mode = On inside the app.

If the API key is missing or invalid, the app automatically falls back to rule-based output.

## Folder Structure

```
/ClassIII_DecisionApp
    ├── ClassIII_DecisionApp.m      
    ├── README.md                   
    ├── /Executable                 
    └── /Documentation              
```

## Citation

If you use this software in research or clinical studies, please cite:

Tanikawa C. ClassIII_DecisionApp: Fuzzy–AI decision support system for treatment selection in skeletal Class III malocclusion. 2025.

## License

This software is provided for academic and clinical research use.  
Commercial use requires permission from the author.

## Contact

For questions, feedback, or collaboration:  
**Dr. Chihiro Tanikawa**  
Osaka University Graduate School of Dentistry  
tanikawa.chihiro.dent@osaka-u.ac.jp

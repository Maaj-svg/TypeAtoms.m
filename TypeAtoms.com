import tkinter as tk
from tkinter import Menu, scrolledtext, filedialog, messagebox
import speech_recognition as sr
import pyttsx3
from textblob import TextBlob
import pyperclip
import language_tool_python
import spacy

# Load SpaCy model
nlp = spacy.load("en_core_web_sm")

# Initialize LanguageTool
tool = language_tool_python.LanguageToolPublicAPI("en-US")

def correct_spelling():
    text = text_area.get("1.0", tk.END).strip()
    if text:
        blob = TextBlob(text)
        corrected_text = str(blob.correct())
        text_area.delete("1.0", tk.END)
        text_area.insert(tk.END, corrected_text)

def check_grammar():
    text = text_area.get("1.0", tk.END).strip()
    if text:
        matches = tool.check(text)
        corrected_text = language_tool_python.utils.correct(text, matches)
        text_area.delete("1.0", tk.END)
        text_area.insert(tk.END, corrected_text)

def voice_to_text():
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        status_label.config(text="Listening... Speak now.")
        root.update()
        try:
            audio = recognizer.listen(source)
            text = recognizer.recognize_google(audio)
            text_area.insert(tk.END, text + " ")
        except sr.UnknownValueError:
            status_label.config(text="Could not understand the audio.")
        except sr.RequestError:
            status_label.config(text="Speech Recognition service is unavailable.")
        else:
            status_label.config(text="Ready")

def on_right_click(event):
    menu = Menu(root, tearoff=0)
    menu.add_command(label="Copy", command=copy_text)
    menu.add_command(label="Paste", command=paste_text)
    menu.post(event.x_root, event.y_root)

def copy_text():
    text = text_area.get("1.0", tk.END).strip()
    if text:
        pyperclip.copy(text)

def paste_text():
    text = pyperclip.paste()
    text_area.insert(tk.END, text)

def save_text():
    text = text_area.get("1.0", tk.END).strip()
    if text:
        file_path = filedialog.asksaveasfilename(defaultextension=".txt", filetypes=[("Text files", "*.txt"), ("All files", "*.*")])
        if file_path:
            with open(file_path, "w", encoding="utf-8") as file:
                file.write(text)

def load_text():
    file_path = filedialog.askopenfilename(filetypes=[("Text files", "*.txt"), ("All files", "*.*")])
    if file_path:
        with open(file_path, "r", encoding="utf-8") as file:
            content = file.read()
            text_area.delete("1.0", tk.END)
            text_area.insert(tk.END, content)

# UI Setup
root = tk.Tk()
root.title("TypeAtoms - Powerful Text Corrector")
root.geometry("800x500")
root.configure(bg="#f8f9fa")

status_label = tk.Label(root, text="Ready", font=("Arial", 12), bg="#f8f9fa")
status_label.pack(pady=5)

text_area = scrolledtext.ScrolledText(root, wrap="word", font=("Arial", 14), bg="white", fg="black", height=15)
text_area.pack(expand=True, fill=tk.BOTH, padx=10, pady=10)
text_area.bind("<Button-3>", on_right_click)

button_frame = tk.Frame(root, bg="#f8f9fa")
button_frame.pack(pady=10)

spell_btn = tk.Button(button_frame, text="Correct Spelling", command=correct_spelling, font=("Arial", 12), bg="#28a745", fg="white", padx=10, pady=5)
spell_btn.grid(row=0, column=0, padx=10)

grammar_btn = tk.Button(button_frame, text="Check Grammar", command=check_grammar, font=("Arial", 12), bg="#17a2b8", fg="white", padx=10, pady=5)
grammar_btn.grid(row=0, column=1, padx=10)

voice_btn = tk.Button(button_frame, text="Voice to Text", command=voice_to_text, font=("Arial", 12), bg="#007bff", fg="white", padx=10, pady=5)
voice_btn.grid(row=0, column=2, padx=10)

copy_btn = tk.Button(button_frame, text="Copy Text", command=copy_text, font=("Arial", 12), bg="#ffc107", fg="black", padx=10, pady=5)
copy_btn.grid(row=0, column=3, padx=10)

paste_btn = tk.Button(button_frame, text="Paste Text", command=paste_text, font=("Arial", 12), bg="#ff851b", fg="white", padx=10, pady=5)
paste_btn.grid(row=0, column=4, padx=10)

save_btn = tk.Button(button_frame, text="Save Text", command=save_text, font=("Arial", 12), bg="#6c757d", fg="white", padx=10, pady=5)
save_btn.grid(row=0, column=5, padx=10)

load_btn = tk.Button(button_frame, text="Load Text", command=load_text, font=("Arial", 12), bg="#6610f2", fg="white", padx=10, pady=5)
load_btn.grid(row=0, column=6, padx=10)

root.mainloop()

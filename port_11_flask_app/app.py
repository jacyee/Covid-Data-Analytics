from flask import Flask, render_template, request, redirect
import speech_recognition as sr

app = Flask(__name__) #set Flask app

@app.route("/", methods = ["GET","POST"])

def index():

    transcript = ""

    if request.method == "POST":
        print("form data received")
        
        # check if file exists or filename exists, redirect to homepage
        if "file" not in request.files:
            return redirect(request.url)

        file = request.files['file']

        if file.filename=="":
            return redirect(request.url)
        
        if file:
            recognizer = sr.Recognizer()
            audioFile = sr.AudioFile(file) # create audiofile object
            with audioFile as source:
                data = recognizer.record(source)
            transcript = recognizer.recognize_google(data,key=None) #text-from-audio

    return render_template('index.html',transcript = transcript)

if __name__ == "__main__":
    app.run(debug = True, threaded=True)
import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate, UITextFieldDelegate {

    var audioPlayer: AVAudioPlayer!
    var audioFile: URL!
    let MAX_VOLUME: Float = 10.0
    var progressTimer: Timer!
    let timePlayerSelector: Selector = #selector(ViewController.updatePlayTime)
    let timeRecordSelector: Selector = #selector(ViewController.updateRecordTime)
    var audioFilePath: String?
    var audioRecorder: AVAudioRecorder!
    var isRecordMode = false
    var imgHana: UIImage?
    var speechSynthesizer = AVSpeechSynthesizer() // AVSpeechSynthesizer 객체 추가
    var savedOutputText: String? // 저장된 텍스트를 저장할 변수

    @IBOutlet var pvProgressPlay: UIProgressView!
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var lblEndTime: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    @IBOutlet var slVolume: UISlider!
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lblRecordTime: UILabel!

    @IBOutlet var inputText: UITextView!
    @IBOutlet var outputText: UITextView!
    @IBOutlet var btnExecution: UIButton!
    @IBOutlet var btnClose: UIButton!
    @IBOutlet var lbView: UIView!
    @IBOutlet var lbquestion: UILabel!
    @IBOutlet var btnSelect1: UIButton!
    @IBOutlet var btnSelect2: UIButton!
    @IBOutlet var btnReplay: UIButton!
    @IBOutlet var imgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imgHana = UIImage(named: "hana.png")
        imgView.image = imgHana
        
        selectAudioFile()
        if !isRecordMode {
            initPlay()
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
        } else {
            initRecord()
        }
       
        setupRecordButton() // 녹음 버튼 설정 메소드 호출
        btnExecution.isHidden = true
        btnClose.isHidden = true
        
        pvProgressPlay.isHidden = true
        lblCurrentTime.isHidden = true
        lblEndTime.isHidden = true
        btnPlay.isHidden = true
        btnPause.isHidden = true
        btnStop.isHidden = true
        slVolume.isHidden = true
        
        // Hide additional elements initially
        lbView.isHidden = true
        lbquestion.isHidden = true
        btnSelect1.isHidden = true
        btnSelect2.isHidden = true
        btnReplay.isHidden = true
        
        makeCircularButton(button: btnRecord)
    }

    func makeCircularButton(button: UIButton) {
        button.layer.cornerRadius = button.frame.size.width / 2
        button.clipsToBounds = true
    }

    func setupRecordButton() {
        // 초기 상태는 녹음 시작 버튼으로 설정
        btnRecord.setImage(UIImage(systemName: "mic.fill"), for: .normal)
    }

    func selectAudioFile() {
        if (!isRecordMode) {
            audioFile = Bundle.main.url(forResource: "song", withExtension: "mp3")
        } else {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.wav")
            audioFilePath = audioFile.path
            print("File path: \(audioFilePath ?? "Not found")")
        }
    }

    func initRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            print("Audio session is set up for record and playback")
        } catch let error as NSError {
            print("Error-setCategory: \(error)")
        }

        let recordSettings = [
            AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM as UInt32), // WAV 포맷
            AVLinearPCMBitDepthKey: 16,                                      // 비트 깊이
            AVLinearPCMIsBigEndianKey: false,                                // 빅 엔디언 사용 여부
            AVLinearPCMIsFloatKey: false,                                    // 부동 소수점 샘플 사용 여부
            AVSampleRateKey: 16000.0,                                        // 샘플 레이트
            AVNumberOfChannelsKey: 1                                         // 채널 수
        ] as [String: Any]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
        } catch let error as NSError {
            print("Error-initRecord: \(error)")
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func initPlay() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay: \(error)")
        }

        slVolume.maximumValue = MAX_VOLUME
        slVolume.value = 1.0
        pvProgressPlay.progress = 0

        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer.volume = slVolume.value

        lblEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        lblCurrentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(true, pause: false, stop: false)
    }

    func setPlayButtons(_ play: Bool, pause: Bool, stop: Bool) {
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }

    func convertNSTimeInterval2String(_ time: TimeInterval) -> String {
        let min = Int(time / 60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }

    @IBAction func btnPlayAudio(_ sender: UIButton) {
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }

    @objc func updatePlayTime() {
        lblCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        pvProgressPlay.progress = Float(audioPlayer.currentTime / audioPlayer.duration)
    }

    @IBAction func btnPauseAudio(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
    }

    @IBAction func btnStopAudio(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        lblCurrentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(true, pause: true, stop: false)
        progressTimer.invalidate()
    }

    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = slVolume.value
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setPlayButtons(true, pause: false, stop: false)
    }

    @IBAction func swRecordMode(_ sender: UISwitch) {
        if sender.isOn {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            lblRecordTime!.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            btnRecord.isEnabled = true
            lblRecordTime.isEnabled = true
        } else {
            isRecordMode = false
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
            lblRecordTime.text = convertNSTimeInterval2String(0)
        }
        selectAudioFile()
        if !isRecordMode {
            initPlay()
        } else {
            initRecord()
        }
    }

    @IBAction func btnRecord(_ sender: UIButton) {
        if sender.currentImage == UIImage(systemName: "mic.fill") {
            // Start recording
            if !audioRecorder.isRecording {
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    audioRecorder.record()
                    sender.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
                    sender.setTitle("녹음중", for: .normal)
                    progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
                } catch let error as NSError {
                    print("Error starting recording: \(error.localizedDescription)")
                }
            }
        } else {
            // Stop recording
            audioRecorder.stop()
            progressTimer.invalidate()
            sender.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            sender.setTitle("누르고 말하기", for: .normal)
            btnPlay.isEnabled = true
            initPlay()

            // Set the input and output text views to show the waiting message
            inputText.text = "요청 내용을 확인 중 입니다."
            outputText.text = "요청 내용을 확인 중 입니다."
            
            if let path = audioFilePath {
                uploadAudioFile(filePath: path)
            }
        }
    }

    @objc func updateRecordTime() {
        lblRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }

    func uploadAudioFile(filePath: String) {
        print("Preparing to upload audio file at path: \(filePath)")

        guard let url = URL(string: "http://43.201.128.190:8080/api/v1/voice-assistant/process-voice") else {
            print("Error: Invalid URL")
            return
        }
        print("URL is valid: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        print("Boundary for multipart form data: \(boundary)")

        do {
            let audioData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            print("Audio data loaded successfully. Data length: \(audioData.count) bytes")

            var body = Data()

            // 파일 데이터 추가
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"voiceFile\"; filename=\"recordFile.wav\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)

            // boundary 종료 추가
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body
            print("Request body constructed.")

        } catch {
            print("Error loading audio data: \(error)")
            return
        }

        let session = URLSession.shared
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error during URLSession data task: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                print("Server error or invalid response")
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        if let transcribedText = jsonResponse["transcribedText"] as? String,
                           let generatedText = jsonResponse["generatedText"] as? String {
                            self?.inputText.text = transcribedText
                            self?.outputText.text = generatedText
                            
                            // Show the previously hidden UI elements
                            self?.btnExecution.isHidden = false
                            self?.btnClose.isHidden = false
                            self?.lbView.isHidden = false
                            self?.lbquestion.isHidden = false
                            self?.btnSelect1.isHidden = false
                            self?.btnSelect2.isHidden = false
                            self?.btnReplay.isHidden = false

                            // Add text-to-speech functionality
                            self?.speakText(generatedText)
                            self?.savedOutputText = generatedText //저장된 텍스트 업데이트
                        }
                    }
                }
            } catch {
                print("Error parsing JSON from response: \(error)")
            }
        }.resume()
        print("Data task resumed for uploading audio file.")
    }

    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        speechSynthesizer.speak(utterance)
    }

    @IBAction func btnReplayPressed(_ sender: UIButton) {
        if let text = savedOutputText {
                speakText(text)
            }
    }
    @IBAction func btnClosePressed(_ sender: UIButton) {
        btnExecution.isHidden = true
        btnClose.isHidden = true
        lbView.isHidden = true
        lbquestion.isHidden = true
        btnSelect1.isHidden = true
        btnSelect2.isHidden = true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

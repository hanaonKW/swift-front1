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

    @IBOutlet var pvProgressPlay: UIProgressView!
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var lblEndTime: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    @IBOutlet var slVolume: UISlider!
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lblRecordTime: UILabel!

    @IBOutlet var inputLabel: UITextField!
    @IBOutlet var outputLabel: UILabel!
    @IBOutlet var displayButton: UIButton!
    @IBOutlet var inputText: UITextView!
    @IBOutlet var outputText: UITextView!
    @IBOutlet var btnExecution: UIButton!
    @IBOutlet var btnClose: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectAudioFile()
        if !isRecordMode {
            initPlay()
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
        } else {
            initRecord()
        }
        setupKeyboardNotifications()
        inputLabel.delegate = self
        setupRecordButton() // 녹음 버튼 설정 메소드 호출
    }

    // 기존 함수들...

    func setupRecordButton() {
        // 초기 상태는 녹음 시작 버튼으로 설정
        btnRecord.setImage(UIImage(systemName: "mic.fill"), for: .normal)
    }

    func selectAudioFile() {
        if !isRecordMode {
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
            btnPlay.isEnabled = true
            initPlay()
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

        guard let url = URL(string: "http://13.124.197.128/api/v1/voice-assistant/process-voice") else {
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
                            // 활성화
                            self?.btnExecution.isEnabled = true
                            self?.btnClose.isEnabled = true
                        }
                    }
                }
            } catch {
                print("Error parsing JSON from response: \(error)")
            }
        }.resume()
        print("Data task resumed for uploading audio file.")
    }

    @IBAction func displayText(_ sender: UIButton) {
        outputLabel.text = inputLabel.text
    }

    @IBAction func btnClosePressed(_ sender: UIButton) {
        btnExecution.isEnabled = false
        btnClose.isEnabled = false
    }
    
    // Keyboard notifications setup
    func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo,
           let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            let bottomSpace = view.frame.height - (inputLabel.frame.origin.y + inputLabel.frame.height)
            if bottomSpace < keyboardHeight {
                view.frame.origin.y = -(keyboardHeight - bottomSpace)
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//
//  ViewController.swift
//  MusicPlayer
//
//  Created by 위대연 on 2020/04/09.
//  Copyright © 2020 위대연. All rights reserved.
//

import UIKit
import AVFoundation

func eprint(_ items: Any...) {
    print("errMsg: ", separator: "", terminator: "")
    print(items)
}

class ViewController: UIViewController, AVAudioPlayerDelegate {
    // MARK: - Outlets
    @IBOutlet weak var playPauseButton : UIButton!
    @IBOutlet weak var timeLabel : UILabel!
    @IBOutlet weak var progressSlider : UISlider!
    
    // MARK: - Properties
    var player : AVAudioPlayer!
    var timer : Timer!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addViewsWithCode()
        self.initializePlayer()
    }
    
    // MARK: - Func
    func initializePlayer() {
        guard let soundAsset = NSDataAsset(name: "sound") else {
            eprint("음원 파일 에셋을 가져올 수 없습니다.")
            return
        }
        
        do {
            try self.player = AVAudioPlayer(data: soundAsset.data)
            self.player.delegate = self
        } catch let error as NSError {
            eprint("플레이어 초기화 실패")
            eprint("코드 : \(error.code), 메시지 : \(error.localizedDescription)")
        }
        
        self.progressSlider.maximumValue = Float(self.player.duration)
        self.progressSlider.minimumValue = 0
        self.progressSlider.value = Float(self.player.currentTime)
    }
    
    func updateTimeLabelText(time: TimeInterval) {
        let minute = Int(time / 60)
        let second = Int(time.truncatingRemainder(dividingBy: 60))
        let milisecond = Int(time.truncatingRemainder(dividingBy: 1))
        
        let timeText = String(format: "%02ld:%02ld:%02ld", minute,second,milisecond)
        self.timeLabel.text = timeText
    }
    
    func makeAndFireTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            if self.progressSlider.isTracking { return }
            
            self.updateTimeLabelText(time: self.player.currentTime)
            self.progressSlider.value = Float(self.player.currentTime)
            })
        self.timer.fire()
    }
    
    func invalidateTimer() {
        self.timer.invalidate()
        self.timer = nil
    }
    
    func addViewsWithCode() {
        self.addPlayPauseButton()
        self.addTimeLabel()
        self.addProgressSlider()
    }
    
    func addPlayPauseButton() {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(button)
        
        button.setImage(UIImage(named: "button_play"), for: .normal)
        button.setImage(UIImage(named: "button_pause"), for: .selected)
        
        button.addTarget(self, action: #selector(self.touchUpPlayPauseButton(_:)), for: .touchUpInside)
        
        let centerX = button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        let centerY = NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 0.8, constant: 0)
        let width = button.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5)
        let ratio = button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1)
        
        centerX.isActive = true
        centerY.isActive = true
        width.isActive = true
        ratio.isActive = true
        
        self.playPauseButton = button
    }
    
    func addTimeLabel() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(label)
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
        let centerX: NSLayoutConstraint
        centerX = label.centerXAnchor.constraint(equalTo: self.playPauseButton.centerXAnchor)
        
        let top: NSLayoutConstraint
        top = label.topAnchor.constraint(equalTo: self.playPauseButton.bottomAnchor, constant: 8)
        
        centerX.isActive = true
        top.isActive = true
        
        self.timeLabel = label
        self.updateTimeLabelText(time: 0)
    }
    
    func addProgressSlider() {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(slider)
        
        slider.minimumTrackTintColor = .red
        slider.addTarget(self, action: #selector(self.sliderValueChanged(_:)), for: .valueChanged)
        
        let safeAreaGuide = self.view.safeAreaLayoutGuide
        let centerX = slider.centerXAnchor.constraint(equalTo: self.timeLabel.centerXAnchor)
        let top = slider.topAnchor.constraint(equalTo: self.timeLabel.bottomAnchor, constant: 8)
        let leading = slider.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 16)
        let trailing = slider.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -16)
        
        centerX.isActive = true
        top.isActive = true
        leading.isActive = true
        trailing.isActive = true
        
        self.progressSlider = slider
    }
    
    @IBAction func touchUpPlayPauseButton(_ sender:UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            self.player.play()
        } else {
            self.player.pause()
        }
        
        if sender.isSelected {
            self.makeAndFireTimer()
        } else {
            self.invalidateTimer()
        }
    }
    
    @IBAction func sliderValueChanged(_ sender:UISlider) {
        self.updateTimeLabelText(time: TimeInterval(sender.value))
        if sender.isTracking { return }
        self.player.currentTime = TimeInterval(sender.value)
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
        guard let error = error else {
            return
        }
        
        let message : String
        message = "오디오 플레이어 오류 발생 \(error.localizedDescription)"
        
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playPauseButton.isSelected = false
        self.progressSlider.value = 0
        self.updateTimeLabelText(time: 0)
        self.invalidateTimer()
    }
}


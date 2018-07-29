//
//  ChooseDatePopUpVC.swift
//  SolarCalculator
//
//  Created by Aakash Srivastav on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import UIKit

protocol ChooseDateDelegate: class {
    func didSelectDate(_ date: Date)
}

class ChooseDatePopUpVC: BaseVC {
    
    weak var delegate: ChooseDateDelegate?
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var chooseDateBtn: UIButton!
    @IBOutlet weak var pickerContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.datePickerMode = .date
        pickerContainerView.layer.cornerRadius = 8
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        pickerContainerView.transform.translatedBy(x: 0, y: pickerContainerView.frame.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.5) {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            self.pickerContainerView.transform = .identity
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        removePopUp()
    }
    
    private func removePopUp() {
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func chooseDateBtnTapped(_ sender: UIButton) {
        delegate?.didSelectDate(datePicker.date)
        removePopUp()
    }
}

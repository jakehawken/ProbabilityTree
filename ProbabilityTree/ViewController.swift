//  ViewController.swift
//  Created by Jake Hawken on 8/4/19.
//  Copyright © 2019 Jake Hawken. All rights reserved.

import UIKit

class ViewController: UIViewController {
    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var mainButton: UIButton!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    private let tree = ProbabilityTree()
    private let queue = DispatchQueue(label: "ProbabilityTree")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainButton.layer.borderWidth = 1
        mainButton.layer.borderColor = UIColor.blue.cgColor
        mainButton.layer.cornerRadius = 10
        spinner.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        trainTree()
    }
    
    @IBAction private func mainButtonPressed(_ sender: Any) {
        var sentence: String?
        asyncWithLoader(asyncBlock: { [weak self] in
            sentence = self?.tree.generateSentence()
        }, completionBlock: { [weak self] in
            self?.mainLabel.text = sentence
            print(sentence!)
        })
    }
    
    private func trainTree() {
        mainButton.isEnabled = false
        asyncWithLoader(asyncBlock: { [weak self] in
            self?.tree.add(wordSequence: Stories.Lovecraft.callOfCthulhu)
        }, completionBlock: { [weak self] in
            self?.mainLabel.text = "<< tree trained. >>"
            self?.mainButton.isEnabled = true
            self?.tree.logTopTiers()
        })
    }
    
    private func asyncWithLoader(asyncBlock: @escaping ()->(), completionBlock: @escaping ()->() = {}) {
        spinner.startAnimating()
        queue.async {
            asyncBlock()
            DispatchQueue.main.sync { [weak self] in
                self?.spinner.stopAnimating()
                completionBlock()
            }
        }
    }

}


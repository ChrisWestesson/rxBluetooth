//
//  ViewController.swift
//  rxBluetoothSimpleApp
//
//  Created by ChristianWestesson on 2022-08-12.
//

import UIKit
import RxBluetoothKit
import RxCocoa
import RxSwift
import RxBiBinding
import RxDataSources

class ViewController: UIViewController {
    let manager = CentralManager(queue: .main)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}


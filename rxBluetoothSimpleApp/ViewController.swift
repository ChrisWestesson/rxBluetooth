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
import CoreBluetooth

class ViewController: UIViewController {
    let manager = CentralManager(queue: .main)

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func onDoSmthClicked(_sender: UIButton) {
        print("=V=")
        print("=V= DO button clicked")
        
        let state: BluetoothState = manager.state
        print("BluetoothState = ", state)
        
        let serviceUUID = CBUUID.init(string: "0000A002-0000-1000-8000-00805F9B34FB")
        manager.scanForPeripherals(withServices: [serviceUUID])
            .take(1)
            .subscribe(onNext: { scannedPeripheral in
                self.printDevice(scannedPeripheral: scannedPeripheral)
            })
    }
    
    private func printDevice(scannedPeripheral: ScannedPeripheral) {
        let periferal = scannedPeripheral.peripheral
        let advertisementData = scannedPeripheral.advertisementData
        print("-------")
        print("name       : ", periferal.name)
        print("state      : ", periferal.state)
        print("isConnected: ", periferal.isConnected)
        print("manager    : ", periferal.manager)
        print("identifier :  ", periferal.identifier)
        print("name       : ", periferal.name)
        print("peripheral : ", periferal.peripheral)
        print("-------")
        print("advertisementData: ", advertisementData)
        print("-------")
        print("advertisementData: ", advertisementData.serviceUUIDs)
        print("-------")
        
        connectToDevice(scannedPeripheral: scannedPeripheral)
    }
    
    var service: Service? = nil
    private func connectToDevice(scannedPeripheral: ScannedPeripheral) {
          let disposable = scannedPeripheral.peripheral.establishConnection()
            .flatMap{ $0.discoverServices([CBUUID.init(string: "A002")]) }.asObservable()
            .flatMap{ Observable.from($0) }
            .subscribe(onNext: { service in
                print("Discovered service: \(service.uuid)")
                self.service = service
                self.findCharacteristics()
            })
    }

    var readCharac: Characteristic? = nil
    var writeCharac: Characteristic? = nil
    private func findCharacteristics() {
        self.service!.discoverCharacteristics([CBUUID.init(string: "C304"), CBUUID.init(string: "C306")]).asObservable()
                    .flatMap{ Observable.from($0) }
                    .subscribe(onNext: { characteristic in
                        print("Discovered characteristic: \(characteristic.uuid)")
                        if(characteristic.uuid == CBUUID.init(string: "C304")) {
                            self.writeCharac = characteristic
                        }
                        if(characteristic.uuid == CBUUID.init(string: "C306")) {
                            self.readCharac = characteristic
                        }
                        if(self.readCharac != nil && self.writeCharac != nil) {
                            print("BOTH characteristics FOUND")
                            print("-------")
                            self.startListening()
                            self.writeSomething()
                        }
                    })
    }
    
    var listenerDisposable: Disposable? = nil
    private func startListening() {
        self.listenerDisposable = self.readCharac!.observeValueUpdateAndSetNotification()
            .subscribe(onNext: {
                print("RECEIVED DATA: \($0) \($0.value) \([UInt8]($0.value!))")
//                let newValue = $0.value
            })
    }
    
    private func writeSomething() {
        let data = Data([0x01, 0x04, 0x00, 0x65, 0x00, 0x01, 0x21, 0xD5])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("Trying to WRITE: \([UInt8](data))")
            self.writeCharac!.writeValue(data, type: .withResponse)
                .subscribe{ event in
                    print("WRITE RESPONSE \(event)")
                }
        }
    }
    
    private func dataToArray(data: Data) -> [UInt32] {
        var arr2 = Array<UInt32>(repeating: 0, count: data.count/MemoryLayout<UInt32>.stride)
        _ = arr2.withUnsafeMutableBytes{ data.copyBytes(to: $0) }
        return (arr2) // [32, 4, 4294967295]
    }
    
}

extension ContiguousBytes {
    func objects<T>() -> [T] { withUnsafeBytes{ .init($0.bindMemory(to: T.self)) } }
    var uInt16Array: [UInt16] { objects() }
    var int32Array: [Int32] { objects() }
}

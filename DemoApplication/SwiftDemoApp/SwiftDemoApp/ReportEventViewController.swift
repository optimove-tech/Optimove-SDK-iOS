//
//  ReportEventViewController.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 24/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit


class ReportEventViewController: UIViewController
{
 
    @IBOutlet weak var inputsTableView: UITableView!
    
    var events: [OptimoveEvent] = [StringEvent(),NumberEvent(),CombinedEvent()]
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        Optimove.sharedInstance.setScreenEvent(viewControllersIdetifiers: ["main_screen","report_event"], url: nil)
        
        //Table view configurations
        inputsTableView.dataSource = self
        inputsTableView.delegate = self
        inputsTableView.rowHeight = UITableViewAutomaticDimension
    }
}

//Always mandatory
extension ReportEventViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! EventTableViewCell
        
        switch indexPath.row {
        case 0:
            cell.setup(CustomEventType.string, reportCallBack)
            cell.numberInputTextField.isHidden = true
            cell.stringInputTextField.isHidden = false
        case 1:
            cell.setup(CustomEventType.number, reportCallBack)
            cell.numberInputTextField.isHidden = false
            cell.stringInputTextField.isHidden = true
        case 2:
            cell.setup(CustomEventType.combined, reportCallBack)
            cell.numberInputTextField.isHidden = false
            cell.stringInputTextField.isHidden = false
        default:
            return UITableViewCell()
        }
        
        
        return cell
    }
    
    func reportCallBack(error: OptimoveError?)
    {
        DispatchQueue.main.async {
        let alert = UIAlertController(title: "Report Event Response", message: "\(error?.rawValue ?? 0)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert,animated:true,completion: nil)
        }
    }
    
}

//Optional
extension ReportEventViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        Optimove.sharedInstance.reportEvent(event: events[indexPath.row])
    }
}

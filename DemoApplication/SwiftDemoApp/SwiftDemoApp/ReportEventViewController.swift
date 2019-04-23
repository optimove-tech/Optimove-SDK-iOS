

import UIKit
import OptimoveSDK

class ReportEventViewController: UIViewController
{
 
    @IBOutlet weak var inputsTableView: UITableView!
    
    var events: [OptimoveEvent] = [StringEvent(),NumberEvent(),CombinedEvent()]
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        Optimove.shared.setScreenVisit(screenPathArray: ["main_screen","report_event"], screenTitle: "report_event")
        
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
            cell.setup(CustomEventType.string)
            cell.numberInputTextField.isHidden = true
            cell.stringInputTextField.isHidden = false
        case 1:
            cell.setup(CustomEventType.number)
            cell.numberInputTextField.isHidden = false
            cell.stringInputTextField.isHidden = true
        case 2:
            cell.setup(CustomEventType.combined)
            cell.numberInputTextField.isHidden = false
            cell.stringInputTextField.isHidden = false
        default:
            return UITableViewCell()
        }
        
        
        return cell
    }
}

//Optional
extension ReportEventViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        Optimove.shared.reportEvent(events[indexPath.row])
    }
}

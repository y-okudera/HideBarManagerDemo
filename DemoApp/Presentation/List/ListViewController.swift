//
//  ListViewController.swift
//  DemoApp
//
//  Created by okudera on 2020/12/05.
//

import UIKit

class ListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView! {
        willSet {
            newValue.delegate = self
            newValue.dataSource = self
        }
    }
    @IBOutlet private weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableViewBottomConstraint: NSLayoutConstraint!

    private lazy var hideBarManager = HideBarManager.build(
        topConstraint: self.tableViewTopConstraint,
        bottomConstraint: self.tableViewBottomConstraint,
        scrollView: self.tableView,
        tabBar: self.tabBarController?.tabBar,
        navigationBar: self.navigationController?.navigationBar
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "ListViewController"
        self.hideBarManager.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.hideBarManager.viewDidLayoutSubviews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideBarManager.viewWillDisappear()
    }
}

// MARK: - UITableViewDataSource
extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        cell.textLabel?.textColor = .black
        switch indexPath.row / 5 {
        case 0:
            cell.backgroundColor = .red
        case 1:
            cell.backgroundColor = .yellow
        case 2:
            cell.backgroundColor = .green
        case 3:
            cell.backgroundColor = .cyan
        case 4:
            cell.backgroundColor = .magenta
        case 5:
            cell.backgroundColor = .lightGray
        case 6:
            cell.backgroundColor = .darkGray
        case 7:
            cell.backgroundColor = .orange
        case 8:
            cell.backgroundColor = .purple
        case 9:
            cell.backgroundColor = .brown
        default:
            cell.backgroundColor = .white
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(#function)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension ListViewController: UIScrollViewDelegate {

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        self.hideBarManager.scrollViewShouldScrollToTop()
        return true
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.hideBarManager.scrollViewWillBeginDragging()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.hideBarManager.scrollViewDidEndDragging(decelerate: decelerate)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.hideBarManager.scrollViewDidScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.hideBarManager.scrollViewDidEndDecelerating()
    }
}

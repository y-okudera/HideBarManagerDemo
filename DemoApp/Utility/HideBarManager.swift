//
//  HideBarManager.swift
//  DemoApp
//
//  Created by okudera on 2020/12/05.
//

import UIKit

/// スクロール時のNavigationBar, TabBar表示/非表示切り替え用マネージャー
///
/// - Note: TabBarController ⊃ NavigationController ⊃ ViewController ⊃ ScrollViewの構成を想定
final class HideBarManager {

    /// スクロールビューのTopの制約
    ///
    /// - Note: Topの制約は、SafeAreaInsets.TopではなくSuperview.Topに対して設定してください
    private weak var topConstraint: NSLayoutConstraint?
    /// スクロールビューのBottomの制約
    ///
    /// - Note: Bottomの制約は、SafeAreaInsets.BottomではなくSuperview.Bottomに対して設定してください
    private weak var bottomConstraint: NSLayoutConstraint?
    /// スクロールビュー
    private weak var scrollView: UIScrollView!
    /// タブバー
    private weak var tabBar: UITabBar?
    /// ナビゲーションバー
    private weak var navigationBar: UINavigationBar?

    /// タブバーのフレーム
    private var tabBarDefaultFrame: CGRect!
    /// ナビゲーションバーのフレーム
    private var navigationBarDefaultFrame: CGRect!
    /// スクロール開始時の位置
    private var scrollBeginningOffsetY: CGFloat?
    /// タブバーの移動量
    private var tabBarMovingDistance: CGFloat = 0
    /// ナビゲーションバーの移動量
    private var navigationBarMovingDistance: CGFloat = 0
    /// スクロール方向
    private var scrollDirectionY = UIScrollView.ScrollDirectionY.none

    private init() {}

    static func build(topConstraint: NSLayoutConstraint?,
                      bottomConstraint: NSLayoutConstraint?,
                      scrollView: UIScrollView!,
                      tabBar: UITabBar?,
                      navigationBar: UINavigationBar?) -> HideBarManager {
        let hideBarManager = HideBarManager()
        hideBarManager.topConstraint = topConstraint
        hideBarManager.bottomConstraint = bottomConstraint
        hideBarManager.scrollView = scrollView
        hideBarManager.tabBar = tabBar
        hideBarManager.navigationBar = navigationBar
        return hideBarManager
    }
}

extension HideBarManager {

    func viewDidLoad() {
        self.addObservers()
    }

    func viewDidLayoutSubviews() {
        // 初回のみ代入したいためnilチェックもする
        if let tabBar = self.tabBar {
            self.tabBarDefaultFrame = self.tabBarDefaultFrame ?? tabBar.frame
        }
        if let navigationBar = self.navigationBar {
            self.navigationBarDefaultFrame = self.navigationBarDefaultFrame ?? navigationBar.frame
        }
        self.updateConstraints()
    }

    func viewWillDisappear() {
        self.showBarImmediately()
    }

    func scrollViewShouldScrollToTop() {
        self.showBarImmediately()
    }

    /// ドラッグ開始
    func scrollViewWillBeginDragging() {
        if self.scrollBeginningOffsetY == nil {
            self.scrollBeginningOffsetY = self.scrollView.contentOffset.y
            self.tabBarMovingDistance = 0
            self.navigationBarMovingDistance = 0
        }
    }

    /// ドラッグ終了
    func scrollViewDidEndDragging(decelerate: Bool) {
        if !decelerate {
            self.scrollBeginningOffsetY = nil
            self.scrollDirectionY = .none
        }
    }

    /// スクロール中
    func scrollViewDidScroll() {
        guard self.scrollView.isDragging else {
            return
        }
        let scrollViewHeight = scrollView.frame.size.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        let scrollBeginningOffset = self.scrollBeginningOffsetY ?? 0

        // 一番上に到達
        if scrollOffset <= 0 {
            self.showBarImmediately()
            return
        }

        // 一番下に到達
        if scrollContentSizeHeight <= scrollOffset + scrollViewHeight {
            return
        }

        // 下へスクロール
        if scrollBeginningOffset < scrollOffset {
            if self.scrollDirectionY == .none || self.scrollDirectionY == .bottom {
                self.scrollDirectionY = .bottom
                self.moveTabBarAndNavigationBar()
                return
            }
        }

        // 上へスクロール
        if scrollBeginningOffset > scrollOffset {
            if self.scrollDirectionY == .none || self.scrollDirectionY == .top {
                self.scrollDirectionY = .top
                self.moveTabBarAndNavigationBar()
                return
            }
        }
    }

    /// スクロール停止
    func scrollViewDidEndDecelerating() {
        self.scrollBeginningOffsetY = nil
        self.scrollDirectionY = .none
    }
}

// MARK: - Private functions
extension HideBarManager {

    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showBarImmediately),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showBarImmediately),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }

    /// タブバーとナビゲーションバーを表示させる
    @objc private func showBarImmediately() {
        self.tabBar?.frame = self.tabBarDefaultFrame
        self.navigationBar?.frame = self.navigationBarDefaultFrame
        self.tabBarMovingDistance = 0
        self.navigationBarMovingDistance = 0
        self.updateConstraints()
    }

    /// TopとBottomの制約を更新する
    private func updateConstraints() {
        guard let superview = self.scrollView.superview else {
            return
        }
        if self.tabBar != nil {
            self.bottomConstraint?.constant = -superview.safeAreaInsets.bottom + self.tabBarMovingDistance
        }
        if self.navigationBar != nil {
            self.topConstraint?.constant = superview.safeAreaInsets.top + self.navigationBarMovingDistance
        }
    }

    /// タブバーとナビゲーションバーを移動させる
    private func moveTabBarAndNavigationBar() {
        guard
            let tabBarFrame = self.calcTabBarFrame(),
            let navigationBarFrame = self.calcNavigationBarFrame() else {
            return
        }
        self.tabBar?.frame = tabBarFrame
        self.navigationBar?.frame = navigationBarFrame
        self.tabBarMovingDistance = tabBarFrame.origin.y - self.tabBarDefaultFrame.origin.y
        self.navigationBarMovingDistance = navigationBarFrame.origin.y - self.navigationBarDefaultFrame.origin.y
        self.updateConstraints()
    }

    /// スクロール量からタブバーのオフセットを算出し、タブバーのフレームを返す
    private func calcTabBarFrame() -> CGRect? {
        guard let scrollBeginningOffsetY = self.scrollBeginningOffsetY else {
            return nil
        }
        // 移動量
        let movingDistance = self.scrollView.contentOffset.y - scrollBeginningOffsetY

        var newTabBarOriginY = self.tabBarDefaultFrame.origin.y + movingDistance

        // もとの位置より上には移動させない
        let min = self.tabBarDefaultFrame.origin.y
        if newTabBarOriginY < min {
            newTabBarOriginY = min
        }
        // 画面外に出たらそれ以上は下に移動させない
        let max = self.tabBarDefaultFrame.origin.y + (self.tabBarDefaultFrame.size.height * 2)
        if newTabBarOriginY > max {
            newTabBarOriginY = max
        }

        var newTabBarFrame = self.tabBarDefaultFrame!
        newTabBarFrame.origin.y = newTabBarOriginY
        return newTabBarFrame
    }

    /// スクロール量からナビゲーションバーのオフセットを算出し、ナビゲーションバーのフレームを返す
    private func calcNavigationBarFrame() -> CGRect? {
        guard let scrollBeginningOffsetY = self.scrollBeginningOffsetY else {
            return nil
        }
        // 移動量
        let movingDistance = self.scrollView.contentOffset.y - scrollBeginningOffsetY

        var newNavigationBarOriginY = self.navigationBarDefaultFrame.origin.y - movingDistance

        let statusBarHeight = self.scrollView.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0

        // 画面外に出たらそれ以上は上に移動させない
        let min = self.navigationBarDefaultFrame.origin.y - (self.navigationBarDefaultFrame.size.height * 2) - statusBarHeight
        if newNavigationBarOriginY < min {
            newNavigationBarOriginY = min
        }
        // もとの位置より下には移動させない
        let max = self.navigationBarDefaultFrame.origin.y
        if newNavigationBarOriginY > self.navigationBarDefaultFrame.origin.y {
            newNavigationBarOriginY = max
        }

        var newNavigationBarFrame = self.navigationBarDefaultFrame!
        newNavigationBarFrame.origin.y = newNavigationBarOriginY
        return newNavigationBarFrame
    }
}

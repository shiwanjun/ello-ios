//
//  StreamableViewController.swift
//  Ello
//
//  Created by Colin Gray on 2/5/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import UIKit

public protocol PostTappedDelegate : NSObjectProtocol {
    func postTapped(post: Post)
    func postTapped(#postId: String)
}

public protocol UserTappedDelegate : NSObjectProtocol {
    func userTapped(user: User)
}

public protocol CreateCommentDelegate: NSObjectProtocol {
    func createComment(post: Post, text:String, fromController: StreamViewController)
}

public protocol InviteResponder: NSObjectProtocol {
    func onInviteFriends()
}

public class StreamableViewController : BaseElloViewController, PostTappedDelegate {

    var scrollLogic: ElloScrollLogic!
    var experienceUpdatable: ExperienceUpdatable

    override public func viewDidLoad() {
        super.viewDidLoad()

        scrollLogic = ElloScrollLogic(
            onShow: self.showNavBars,
            onHide: self.hideNavBars
        )
    }

    func willPresentStreamable(navBarsVisible : Bool) {
        let view = self.view

        if navBarsVisible {
            showNavBars(false)
        }
        else {
            hideNavBars()
        }
        scrollLogic.isShowing = navBarsVisible
    }

    func showNavBars(scrollToBottom : Bool) {
        if let tabBarController = self.elloTabBarController {
            tabBarController.setTabBarHidden(false, animated: true)
        }
    }

    func hideNavBars() {
        if let tabBarController = self.elloTabBarController {
            tabBarController.setTabBarHidden(true, animated: true)
        }
    }

    @IBAction func backTapped(sender: UIButton) {
        if let controllers = self.navigationController?.childViewControllers {
            if controllers.count > 1 {
                if let prev = controllers[controllers.count - 2] as? StreamableViewController {
                    prev.willPresentStreamable(scrollLogic.isShowing)
                    self.navigationController?.popViewControllerAnimated(true)
                }
                else {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
        }
    }

    private func alreadyOnUserProfile(user: User) -> Bool {
        if let profileVC = self.navigationController?.topViewController as? ProfileViewController {
            let param = profileVC.userParam
            if param[param.startIndex] == "~" {
                let usernamePart = param[advance(param.startIndex, 1)..<param.endIndex]
                return user.username == usernamePart
            }
            else {
                return user.id == profileVC.userParam
            }
        }
        return false
    }

// MARK: PostTappedDelegate

    public func postTapped(post: Post) {
        self.postTapped(postId: post.id)
    }

    public func postTapped(#postId: String) {
        let vc = PostDetailViewController(postParam: postId)
        vc.currentUser = currentUser
        vc.willPresentStreamable(scrollLogic.isShowing)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: UserTappedDelegate
extension StreamableViewController: UserTappedDelegate {
    public func userTapped(user: User) {
        if alreadyOnUserProfile(user.id) {
            return
        }

        let vc = ProfileViewController(userParam: user.id)
        vc.currentUser = currentUser
        vc.willPresentStreamable(scrollLogic.isShowing)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: CreateCommentDelegate
extension StreamableViewController: CreateCommentDelegate {
    public func createComment(post : Post, text: String, fromController: StreamViewController) {
        let vc = OmnibarViewController(parentPost: post, defaultText: text)
        vc.currentUser = self.currentUser
        vc.onCommentSuccess() { (comment: Comment) in
            self.navigationController?.popViewControllerAnimated(true)
            self.commentCreated(comment, fromController: fromController)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    // child classes should override this method and add the comment to their
    // datasource.
    func commentCreated(comment: Comment, fromController: StreamViewController) {}
}

// MARK: StreamScrollDelegate
extension StreamableViewController : StreamScrollDelegate {
    public func streamViewDidScroll(scrollView : UIScrollView) {
        scrollLogic.scrollViewDidScroll(scrollView)
    }

    public func streamViewWillBeginDragging(scrollView: UIScrollView) {
        scrollLogic.scrollViewWillBeginDragging(scrollView)
    }

    public func streamViewDidEndDragging(scrollView: UIScrollView, willDecelerate: Bool) {
        scrollLogic.scrollViewDidEndDragging(scrollView, willDecelerate: willDecelerate)
    }
}

// MARK: InviteResponder
extension StreamableViewController: InviteResponder {
    public func onInviteFriends() {
        Tracker.sharedTracker.inviteFriendsTapped()
        if AddressBook.needsAuthentication() {
            displayContactActionSheet()
        } else {
            getAddressBook(AlertAction(title: "", style: .Light, handler: .None))
        }
    }

    // MARK: - Private

    private func displayContactActionSheet() {
        let alertController = AlertViewController(message: "Import your contacts fo find your friends on Ello.\n\nEllo does not sell user data and never contacts anyone without your permission.")

        let action = AlertAction(title: "Import my contacts", style: .Dark) { action in
            Tracker.sharedTracker.importContactsInitiated()
            self.getAddressBook(action)
        }
        alertController.addAction(action)

        let cancelAction = AlertAction(title: "Not now", style: .Light) { _ in
            Tracker.sharedTracker.importContactsDenied()
        }
        alertController.addAction(cancelAction)

        presentViewController(alertController, animated: true, completion: .None)
    }

    private func getAddressBook(action: AlertAction) {
        Tracker.sharedTracker.addressBookAccessed()
        AddressBook.getAddressBook { result in
            dispatch_async(dispatch_get_main_queue()) {
                switch result {
                case let .Success(box):
                    Tracker.sharedTracker.contactAccessPreferenceChanged(true)
                    let vc = AddFriendsContainerViewController(addressBook: box.value)
                    vc.currentUser = self.currentUser
                    self.navigationController?.pushViewController(vc, animated: true)
                case let .Failure(box):
                    Tracker.sharedTracker.contactAccessPreferenceChanged(false)
                    self.displayAddressBookAlert(box.value.rawValue)
                    return
                }
            }
        }
    }

    private func displayAddressBookAlert(message: String) {
        let alertController = AlertViewController(
            message: "We were unable to access your address book\n\(message)"
        )

        let action = AlertAction(title: "OK", style: .Dark, handler: .None)
        alertController.addAction(action)

        presentViewController(alertController, animated: true, completion: .None)
    }
}

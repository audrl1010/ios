//
//  JoinViewController.swift
//  AloneSocialClub
//
//  Created by Suyeol Jeon on 07/10/2019.
//

import AuthenticationServices
import UIKit

import AsyncDisplayKit
import BonMot
import Pure
import ReactorKit
import RxRelay
import RxSwift

final class JoinViewController: BaseViewController, View, FactoryModule {

  // MARK: Module

  struct Dependency {
    let reactorFactory: JoinViewReactor.Factory
    let sceneSwitcher: SceneSwitcher
  }

  struct Payload {
    let reactor: JoinViewReactor
  }


  // MARK: Constants

  private enum Typo {
    static let title = StringStyle([
      .font(.systemFont(ofSize: 32, weight: .bold)),
      .color(.oc_gray9)
    ])
    static let placeholder = name.byAdding([
      .color(.oc_gray4)
    ])
    static let name = StringStyle([
      .font(.systemFont(ofSize: 24, weight: .bold)),
      .color(.oc_gray9)
    ])
    static let joinButton = StringStyle([
      .font(.systemFont(ofSize: 18, weight: .bold)),
      .color(.white)
    ])
    static let or = StringStyle([
      .font(.systemFont(ofSize: 16, weight: .semibold)),
      .color(.oc_gray5),
      .alignment(.center)
    ])
  }


  // MARK: Properties

  private let dependency: Dependency
  private let signInWithAppleButtonTap = PublishRelay<Void>()


  // MARK: UI

  private let titleNode = ASTextNode().then {
    $0.attributedText = "Who are you?".styled(with: Typo.title)
  }
  private let nameInputNode = ASEditableTextNode().then {
    $0.attributedPlaceholderText = "Your name".styled(with: Typo.placeholder)
    $0.typingAttributes = Typo.name.rawAttributes
  }
  private let joinButtonNode = ASButtonNode().then {
    $0.setAttributedTitle("Next".styled(with: Typo.joinButton), for: .normal)
    $0.setBackgroundImage(UIImage.resizable().corner(radius: 5).color(.oc_blue5).image, for: .normal)
    $0.setBackgroundImage(UIImage.resizable().corner(radius: 5).color(.oc_blue7).image, for: .highlighted)
  }

  private let orTextNode = ASTextNode().then {
    $0.attributedText = "OR".styled(with: Typo.or)
  }

  private let signInWithAppleButton: ASAuthorizationAppleIDButton
  private let signInWithAppleButtonNode: ASDisplayNode

  private let activityIndicatorNode = ActivityIndicatorNode(style: .medium)


  // MARK: Initializing

  init(dependency: Dependency, payload: Payload) {
    defer { self.reactor = payload.reactor }
    self.dependency = dependency

    let signInWithAppleButton = ASAuthorizationAppleIDButton()
    signInWithAppleButton.cornerRadius = 5
    self.signInWithAppleButton = signInWithAppleButton
    self.signInWithAppleButtonNode = ASDisplayNode(viewBlock: { signInWithAppleButton })

    super.init()

    self.signInWithAppleButton.addTarget(self, action: #selector(didTapSignInWithAppleButton), for: .touchUpInside)
  }

  required convenience init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: View Life Cycle

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.nameInputNode.becomeFirstResponder()
  }


  // MARK: Binding

  func bind(reactor: JoinViewReactor) {
    self.bindJoinButton(reactor: reactor)
    self.bindSignInWithAppleButton(reactor: reactor)
    self.bindNavigation(reactor: reactor)
  }

  private func bindJoinButton(reactor: JoinViewReactor) {
    reactor.state.map { $0.isLoading }
      .distinctUntilChanged()
      .do(afterNext: { [weak self] _ in self?.node.setNeedsLayout() })
      .bind(to: self.joinButtonNode.rx.isHidden)
      .disposed(by: self.disposeBag)

    self.joinButtonNode.rx.tap
      .withLatestFrom(self.nameInputNode.rx.attributedText)
      .filterNil()
      .map { Reactor.Action.join(name: $0.string) }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
  }

  private func bindSignInWithAppleButton(reactor: JoinViewReactor) {
    self.signInWithAppleButtonTap
      .map { Reactor.Action.signInWithApple }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)
  }

  private func bindNavigation(reactor: JoinViewReactor) {
    reactor.state.map { $0.isAuthenticated }
      .distinctUntilChanged()
      .filter { $0 == true }
      .subscribe(onNext: { [weak self] _ in
        self?.dependency.sceneSwitcher.switch(to: .main)
      })
      .disposed(by: self.disposeBag)
  }


  // MARK: Actions

  @objc private func didTapSignInWithAppleButton() {
    self.signInWithAppleButtonTap.accept(Void())
  }


  // MARK: Layout

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let stack = ASStackLayoutSpec(
      direction: .vertical,
      spacing: 0,
      justifyContent: .start,
      alignItems: .stretch,
      children: [
        self.titleNode,
        self.spacing(height: 20),
        self.nameInputNode,
        self.spacing(height: 30),
        self.joinButtonNode.styled {
          $0.preferredSize.height = 40
        },
        self.spacing(height: 30),
        self.orTextNode,
        self.spacing(height: 30),
        self.signInWithAppleButtonNode.styled {
          $0.preferredSize.height = 40
        },
      ]
    )
    return ASInsetLayoutSpec(
      insets: UIEdgeInsets(
        top: self.node.safeAreaInsets.top + 30,
        left: 15,
        bottom: self.node.safeAreaInsets.bottom + 30,
        right: 15
      ),
      child: stack
    )
  }

  private func joinButtonOrActivityIndicatorLayout() -> ASLayoutElement {
    if !self.joinButtonNode.isHidden {
      return self.joinButtonNode
    } else {
      return self.activityIndicatorNode
    }
  }

  private func spacing(width: CGFloat = 0, height: CGFloat = 0) -> ASLayoutElement {
    return ASDisplayNode().styled {
      $0.preferredSize.width = width
      $0.preferredSize.height = height
    }
  }
}

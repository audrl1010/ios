//
//  AuthServiceStub.swift
//  AloneSocialClubTests
//
//  Created by Suyeol Jeon on 2019/10/13.
//

import RxSwift
import Stubber
@testable import AloneSocialClub

final class AuthServiceStub: AuthServiceProtocol {
  func join(name: String) -> Single<User> {
    return Stubber.invoke(join, args: name, default: .error(TestError()))
  }
}
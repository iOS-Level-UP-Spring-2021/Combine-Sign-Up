import Combine
import Foundation

protocol NameValidator {
  func validate(name: String) -> AnyPublisher<String?, Never>
}

class NameValidatorStub: NameValidator {
  func validate(name: String) -> AnyPublisher<String?, Never> {
    return Future { promise in
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
        if name.starts(with: "u") {
          promise(.success(name))
        } else {
          promise(.success(nil))
        }
      }
    }.eraseToAnyPublisher()
  }
}

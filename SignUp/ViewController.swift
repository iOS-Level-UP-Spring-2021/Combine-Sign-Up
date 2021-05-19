import UIKit
import Combine

class ViewController: UIViewController {

  private var nameValidator: NameValidator!

  @IBOutlet weak var submitButton: UIButton!
  @IBOutlet weak var nameFetchingIndicator: UIActivityIndicatorView!

  @Published private var username: String = ""
  @Published private var password: String = ""
  @Published private var passwordAgain: String = ""

  private var cancellables: Set<AnyCancellable> = .init()

  override func viewDidLoad() {
    super.viewDidLoad()
    nameValidator = NameValidatorStub()

    validatedCredentials
      .map { $0 != nil }
      .assign(to: \.isEnabled, on: submitButton)
      .store(in: &cancellables)
  }

  private var validatedCredentials: AnyPublisher<Credentials?, Never> {
    validatedUsername.combineLatest(validatedPassword)
      .map { username, password in
        guard let username = username, let password = password else { return nil }
        return Credentials(username: username, password: password)
      }
      .eraseToAnyPublisher()
  }

  private var validatedUsername: AnyPublisher<String?, Never> {
    $username
      .dropFirst()
      .debounce(for: 0.5, scheduler: RunLoop.main)
      .removeDuplicates()
      .flatMap { [unowned self] username in
        self.nameValidator.validate(name: username)
          .prepend(nil)
          .receive(on: RunLoop.main)
          .handleEvents(
            receiveSubscription: { [weak nameFetchingIndicator] _ in
              nameFetchingIndicator?.startAnimating()
          }, receiveCompletion: { [weak nameFetchingIndicator] _ in
            nameFetchingIndicator?.stopAnimating()
          }, receiveCancel: { [weak nameFetchingIndicator] in
            nameFetchingIndicator?.stopAnimating()
          })
      }
      .eraseToAnyPublisher()
  }

  private var validatedPassword: AnyPublisher<String?, Never> {
    $password.combineLatest($passwordAgain)
      .map { (p1, p2) -> String? in
        guard p1 == p2, p1.count >= 8 else { return nil }  // This is the password validation logic. It should be moved to a separate Publisher (just like NameValidator)
        return p1
    }.eraseToAnyPublisher()
  }

  @IBAction func submitButtonPressed(_ sender: Any) {
    print("Submit credentials")
  }

  @IBAction func usernameDidChange(_ sender: UITextField) {
    username = sender.text ?? ""
  }

  @IBAction func passwordDidChange(_ sender: UITextField) {
    password = sender.text ?? ""
  }

  @IBAction func passwordAgainDidChange(_ sender: UITextField) {
    passwordAgain = sender.text ?? ""
  }
}

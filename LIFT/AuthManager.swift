//
//  AuthManager.swift
//  LIFT
//

import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupListener()
    }
    
    private func setupListener() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = (user != nil)
            }
        }
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func register(email: String, password: String, completion: ((Bool) -> Void)? = nil) {
        isAuthenticating = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                } else {
                    self?.errorMessage = nil
                    completion?(true)
                }
            }
        }
    }
    
    func login(email: String, password: String, completion: ((Bool) -> Void)? = nil) {
        isAuthenticating = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                } else {
                    self?.errorMessage = nil
                    completion?(true)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateProfileName(name: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        
        changeRequest.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    // Re-trigger listener or update published state manually
                    self?.currentUser = Auth.auth().currentUser
                    completion(true)
                }
            }
        }
    }
}

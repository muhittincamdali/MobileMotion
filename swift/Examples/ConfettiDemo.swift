//
//  ConfettiDemo.swift
//  MobileMotion Examples
//
//  Created by Muhittin Camdali
//  Copyright © 2025 MobileMotion. All rights reserved.
//

import UIKit
import MobileMotion

// MARK: - Confetti Demo View Controller

/// A demonstration view controller showcasing the confetti particle system
public final class ConfettiDemoViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "🎉 Confetti Demo"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap anywhere or use the buttons below to trigger confetti effects"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var celebrationButton: UIButton = {
        createButton(title: "🎊 Celebration", action: #selector(triggerCelebration))
    }()
    
    private lazy var explosionButton: UIButton = {
        createButton(title: "💥 Explosion", action: #selector(triggerExplosion))
    }()
    
    private lazy var heartsButton: UIButton = {
        createButton(title: "❤️ Hearts", action: #selector(triggerHearts))
    }()
    
    private lazy var subtleButton: UIButton = {
        createButton(title: "✨ Subtle", action: #selector(triggerSubtle))
    }()
    
    private lazy var customButton: UIButton = {
        createButton(title: "🌈 Custom Rainbow", action: #selector(triggerCustom))
    }()
    
    private var confettiTrigger: ConfettiTrigger?
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        
        confettiTrigger = ConfettiTrigger(targetView: view)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(buttonStackView)
        
        [celebrationButton, explosionButton, heartsButton, subtleButton, customButton].forEach {
            buttonStackView.addArrangedSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            buttonStackView.heightAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Actions
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        
        // Don't trigger on buttons
        guard !buttonStackView.frame.contains(location) else { return }
        
        view.showConfettiBurst(at: location)
    }
    
    @objc private func triggerCelebration() {
        confettiTrigger?.fire(preset: .celebration)
    }
    
    @objc private func triggerExplosion() {
        confettiTrigger?.fire(preset: .explosion)
    }
    
    @objc private func triggerHearts() {
        confettiTrigger?.fire(preset: .hearts)
    }
    
    @objc private func triggerSubtle() {
        confettiTrigger?.fire(preset: .subtle)
    }
    
    @objc private func triggerCustom() {
        let rainbowConfig = ConfettiConfiguration(
            particleCount: 150,
            emissionDuration: 1.0,
            colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .systemPink],
            shapes: [.star, .circle, .heart],
            minSize: CGSize(width: 8, height: 6),
            maxSize: CGSize(width: 18, height: 14),
            velocityRange: 350...700,
            angleRange: (-.pi * 0.8)...(-.pi * 0.2),
            gravity: 350,
            lifetime: 5.0,
            fadeOut: true,
            spreadAngle: .pi / 3,
            origin: .bottom
        )
        
        confettiTrigger?.fire(preset: .custom(rainbowConfig))
    }
}

// MARK: - Spring Animation Demo

/// Demonstrates spring animation system
public final class SpringAnimationDemoViewController: UIViewController {
    
    // MARK: - Properties
    
    private var animatedViews: [UIView] = []
    private var springSystem: SpringSystem?
    private var positionSprings: [Spring<CGPoint>] = []
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "🌊 Spring Physics"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Drag the circles and watch them spring back"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Bouncy", "Smooth", "Stiff", "Slow"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(springTypeChanged), for: .valueChanged)
        return control
    }()
    
    private var currentSpringParams: SpringParameters = .bouncy
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAnimatedViews()
        setupSpringSystem()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(segmentControl)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            segmentControl.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 20),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupAnimatedViews() {
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple]
        let centerY = view.bounds.midY
        let spacing: CGFloat = 70
        let startX = view.bounds.midX - CGFloat(colors.count - 1) * spacing / 2
        
        for (index, color) in colors.enumerated() {
            let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            circleView.backgroundColor = color
            circleView.layer.cornerRadius = 25
            circleView.center = CGPoint(x: startX + CGFloat(index) * spacing, y: centerY)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            circleView.addGestureRecognizer(panGesture)
            circleView.isUserInteractionEnabled = true
            circleView.tag = index
            
            view.addSubview(circleView)
            animatedViews.append(circleView)
        }
    }
    
    private func setupSpringSystem() {
        springSystem = SpringSystem()
    }
    
    // MARK: - Actions
    
    @objc private func springTypeChanged(_ control: UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0: currentSpringParams = .bouncy
        case 1: currentSpringParams = .smooth
        case 2: currentSpringParams = .stiff
        case 3: currentSpringParams = .slow
        default: break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let circleView = gesture.view else { return }
        let index = circleView.tag
        
        switch gesture.state {
        case .changed:
            let translation = gesture.translation(in: view)
            circleView.center = CGPoint(
                x: circleView.center.x + translation.x,
                y: circleView.center.y + translation.y
            )
            gesture.setTranslation(.zero, in: view)
            
        case .ended:
            let originalCenter = CGPoint(
                x: view.bounds.midX - CGFloat(animatedViews.count - 1) * 70 / 2 + CGFloat(index) * 70,
                y: view.bounds.midY
            )
            
            let spring = Spring<CGPoint>(
                initialValue: circleView.center,
                target: originalCenter,
                parameters: currentSpringParams
            )
            
            spring.onChange = { [weak circleView] newPosition in
                circleView?.center = newPosition
            }
            
            springSystem?.addSpring(spring, forKey: "circle_\(index)")
            
        default:
            break
        }
    }
}

// MARK: - Gravity Demo

/// Demonstrates gravity physics system
public final class GravityDemoViewController: UIViewController {
    
    // MARK: - Properties
    
    private var gravitySystem: GravitySystem?
    private var bodies: [PhysicsBody] = []
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "🌍 Gravity Physics"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ Add Ball", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addBall), for: .touchUpInside)
        return button
    }()
    
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear All", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGravitySystem()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gravitySystem?.start()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gravitySystem?.stop()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(addButton)
        view.addSubview(clearButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            addButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            
            clearButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            clearButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10)
        ])
    }
    
    private func setupGravitySystem() {
        let config = GravityConfiguration(
            gravity: .down,
            globalDamping: 0.99,
            maxVelocity: 1500,
            enableCollisions: true
        )
        
        gravitySystem = GravitySystem(configuration: config)
        
        // Set bounds
        let playArea = CGRect(
            x: 20,
            y: view.safeAreaInsets.top + 100,
            width: view.bounds.width - 40,
            height: view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - 120
        )
        gravitySystem?.setBounds(playArea, elasticity: 0.7, friction: 0.2)
    }
    
    // MARK: - Actions
    
    @objc private func addBall() {
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemPink]
        let size = CGFloat.random(in: 30...60)
        
        let ballView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        ballView.backgroundColor = colors.randomElement()
        ballView.layer.cornerRadius = size / 2
        ballView.center = CGPoint(
            x: CGFloat.random(in: 50...(view.bounds.width - 50)),
            y: 150
        )
        
        view.addSubview(ballView)
        
        let body = PhysicsBody(view: ballView, mass: size / 30)
        body.elasticity = CGFloat.random(in: 0.5...0.9)
        body.applyImpulse(CGVector(
            dx: CGFloat.random(in: -200...200),
            dy: CGFloat.random(in: -100...100)
        ))
        
        gravitySystem?.addBody(body)
        bodies.append(body)
    }
    
    @objc private func clearAll() {
        gravitySystem?.removeAllBodies()
        
        for body in bodies {
            body.view?.removeFromSuperview()
        }
        bodies.removeAll()
    }
}

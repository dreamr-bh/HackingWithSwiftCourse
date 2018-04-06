//
//  GameScene.swift
//  SwiftyNinja
//
//  Created by Ben Hall on 06/04/2018.
//  Copyright © 2018 BeshBashBosh. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: - Properties
    var gameScore: SKLabelNode!
    var score = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var lives = 3
    
    var activeSliceBG: SKShapeNode! // Background of user swipe node
    var activeSliceFG: SKShapeNode! // Foreground of user swipe node
    var activeSlicePoints = [CGPoint]() // Object to store the slice points
    
    var isSwooshSoundActive = false // Property for limiting number of swoosh sounds played at any one time
    
    // MARK: - Custom Methods
    // Creates socre label node
    func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.horizontalAlignmentMode = .left
        gameScore.text = "Score: 0"
        gameScore.fontSize = 48
        addChild(gameScore)
        
        gameScore.position = CGPoint(x: 8, y: 8)
    }
    
    // Creates lives indicator node
    func createLives() {
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i*70)), y: 720)
            addChild(spriteNode)
            livesImages.append(spriteNode) // Append newly created node to lives array
        }
    }
    
    // Tracks all user interactions and draws lines where user is swiping/slicing
    // Will be one line atop another to give illusion of a glow
    func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = .white
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    // Draw slice using Bezier path
    func redrawActiveSlices() {
        // Need three points to draw a line, if not clear shapes and exit
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        // If more than 12 slice points in slice array need to remove oldest one until at most 12 exist
        // This is purely to limit the length of the shown path
        while activeSlicePoints.count > 12 {
            activeSlicePoints.removeFirst() // Alternatively remove(at: 0)
        }
        
        // Start drawing line at start of first slice point, conitnuing through each slice point
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1 ..< activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        
        // Update slice shape paths so they are drawn using their design (i.e. width+colour)
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
    }
    
    // Method for playing a swoosh sound
    func playSwooshSound() {
        // Set property specifying sound playing to true
        isSwooshSoundActive = true
        
        // Get a random value to pick one of the 3 swoosh sounds to play
        let randomNumber = RandomInt(min: 1, max: 3)
        // Get swoosh file name
        let soundName = "swoosh\(randomNumber).caf"
        
        // Play the swoosh sound
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        // Completion closure sets the sound active to false after sound has played. Above waitForCompletion param
        // when set to true lets spritekit know it needs to wait for completion (duh!)
        run(swooshSound) { [unowned self] in
            self.isSwooshSoundActive = false
        }
    }
    
    override func didMove(to view: SKView) {
        // Add background node to scene
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        // Add some physics to the scene
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
        
        // Initialise the game with custom methods
        createScore() // Create score node
        createLives() // create no of lives node
        createSlices()

    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Remove all existing points in activeSlicePoints array
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        // Get first touch location and add to newly empties activeSlicePoints
        if let touch = touches.first {
            let location = touch.location(in: self)
            activeSlicePoints.append(location)
            
            // Redraw the active slices
            redrawActiveSlices()
            
            // Remove actions currently attached to slice shapes (e.g. if they are currently in the middle of fading out)
            activeSliceBG.removeAllActions()
            activeSliceFG.removeAllActions()
            
            // Set alpha of slice shapes to be fully visible
            // (resets any fading out that may have happened during touchesEnded/Cancelled)
            activeSliceBG.alpha = 1
            activeSliceFG.alpha = 1
        }
 
    }
    
    // Called as user touch transitions across screen
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Figure out where in scene user touched.
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Add location to object storing this information
        activeSlicePoints.append(location)
        
        // Redraw the slice shape
        redrawActiveSlices()
        
        // Play 'swoosh' sound is it hasn't started
        if !isSwooshSoundActive {
            playSwooshSound()
        }
    }
    
    // Called when user stops touching scene
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Fade out slice shapes
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    // Called if user touch is interrupted by an event such as low battery warning
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Just calltouchesEnded
        touchesEnded(touches, with: event)
    }
    
    

}

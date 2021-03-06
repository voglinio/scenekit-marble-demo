//
//  GameViewController.swift
//  Marbles
//
//  Created by Friedrich Gräter on 05/10/14.
//  Copyright (c) 2014 Friedrich Gräter. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import AVFoundation

class GameViewController : UIViewController {
	var scene : SCNScene!
	var cameraNode : SCNNode!
	var floorNode : SCNNode!
	var motionManager : CMMotionManager!
    var engine : AVAudioEngine!

	
	override func viewDidLoad() {
		super.viewDidLoad()
        
        // Audio engine
        engine = AVAudioEngine()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .default)
            let ioBufferDuration = 128.0 / 44100.0
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
            
        } catch {
            
            assertionFailure("AVAudioSession setup error: \(error)")
        }
        
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        print (format)
        engine.connect(input, to: engine.mainMixerNode, format: format)

        assert(engine.inputNode != nil)
        
        try! engine.start()
        
        
		// Setup scene
		scene = SCNScene()
		scene.physicsWorld.speed = 3
    

		// Setup camera
		cameraNode = SCNNode()
		cameraNode.camera = SCNCamera()
		cameraNode.camera?.xFov = 50
		cameraNode.camera?.yFov = 50
		cameraNode.position = SCNVector3(x: 0, y: 2, z: 15)
		scene.rootNode.addChildNode(cameraNode)

		// Setup environment
		setupLights()
		setupFloor()

		// Add first marble
		addMarbleAtAltitude(11)

		// Setup view
		let view = self.view as! SCNView
		view.scene = scene

		// Detect taps
		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(GameViewController.handleTap(rec:)))
		view.gestureRecognizers = [tapRecognizer]

		// Detect motion
		motionManager = CMMotionManager()
		motionManager.accelerometerUpdateInterval = 0.3
		
		motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (accelerometerData, error) in
			let acceleration = accelerometerData?.acceleration

			let accelX = Float(9.8 * (acceleration?.y)!)
			let accelY = Float(-9.8 * (acceleration?.x)!)
			let accelZ = Float(9.8 * (acceleration?.z)!)

			self.scene.physicsWorld.gravity = SCNVector3(x: accelX, y: accelY, z: accelZ)
		}
        
 
	}
	
	func setupLights() {
		// Setup ambient light
		let ambientLightNode = SCNNode()
		ambientLightNode.light = SCNLight()
		ambientLightNode.light!.type = SCNLight.LightType.ambient
		ambientLightNode.light!.color = UIColor.init(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
		scene.rootNode.addChildNode(ambientLightNode)
		
		// Add spotlight
		let spotlightNode = SCNNode()
		spotlightNode.light = SCNLight()
		spotlightNode.light!.type = SCNLight.LightType.spot
		spotlightNode.light!.color = UIColor.white
		spotlightNode.light!.spotInnerAngle = 60;
		spotlightNode.light!.spotOuterAngle = 140;
		spotlightNode.light!.attenuationFalloffExponent = 1
		spotlightNode.position = SCNVector3(x: 0, y: 10, z: 0)
		spotlightNode.rotation = SCNVector4(x: -1, y: 0, z: 0, w: .pi/2)
		scene.rootNode.addChildNode(spotlightNode)
	}
	
	func setupFloor() {
		let floorMaterial = SCNMaterial()
		floorMaterial.diffuse.contents = UIColor.init(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
		
		let floor = SCNFloor()
		floor.materials = [floorMaterial]
		floor.reflectivity = 0.1
		
		floorNode = SCNNode()
		floorNode.geometry = floor
		floorNode.physicsBody = SCNPhysicsBody.static()
		
		scene.rootNode.addChildNode(floorNode)
	}
	
	func addMarbleAtAltitude(_ altitude: Float) {
		let radius = Float(1.0)
		let textureNames = ["orange", "blue", "red"]
		let textureName = textureNames[Int(arc4random()) % textureNames.count]
        let sounds = ["500Hz_dBFS.wav", "1000Hz_dBFS.wav", "2000Hz_dBFS.wav"]

		let marbleMaterial = SCNMaterial()
        let marbleAudio = SCNAudioSource(fileNamed: sounds.randomElement() ?? "500Hz_dBFS.wav")!
        marbleAudio.loops = true
        marbleAudio.isPositional = true
        marbleAudio.volume = 1.0
        marbleAudio.shouldStream =  false
        marbleAudio.load()
		
        marbleMaterial.diffuse.contents = UIImage(named: textureName)
		marbleMaterial.specular.contents = UIColor.white
		
		let marbleGeometry = SCNSphere(radius: CGFloat(radius))
		marbleGeometry.segmentCount = 128
		
		let marble = SCNNode(geometry: marbleGeometry)
		marble.geometry?.materials = [marbleMaterial];
		marble.physicsBody = SCNPhysicsBody.dynamic()
		marble.position = SCNVector3(x: Float(arc4random()) / (Float(UINT32_MAX) * 10), y: altitude + radius, z: 0)
		marble.addAudioPlayer(SCNAudioPlayer(source: marbleAudio))
        marble.runAction(SCNAction.playAudio(marbleAudio, waitForCompletion: true))
 
        scene.rootNode.addChildNode(marble)
 
	}

	@objc func handleTap(rec: UITapGestureRecognizer) {
        let scnVew  = self.view as! SCNView
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: scnVew)
            let hits = scnVew.hitTest(location, options:nil)
            if !hits.isEmpty{
                let tappedNode = hits.first?.node
                
                tappedNode!.removeFromParentNode()
                print ("hit", location, tappedNode!.geometry?.name)
            }else{
                addMarbleAtAltitude(10)
            }
        }
	}
    
    
}

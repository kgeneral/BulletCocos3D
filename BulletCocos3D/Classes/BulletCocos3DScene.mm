/**
 *  BulletCocos3DScene.m
 *  BulletCocos3D
 *
 *  Created by Dae-Yeong Kim on 13. 3. 28..
 *  Copyright __MyCompanyName__ 2013년. All rights reserved.
 */

#import "BulletCocos3DScene.h"
#import "CC3PODResourceNode.h"
#import "CC3ActionInterval.h"
#import "CC3MeshNode.h"
#import "CC3Camera.h"
#import "CC3Light.h"

//#include "objLoader.h"

@implementation BulletCocos3DScene

-(void) dealloc {
	[super dealloc];
}
-(void)addBox:(btVector3)position {
    //create a dynamic rigidbody
    
    btCollisionShape* colShape = new btBoxShape(btVector3(1,1,1));
    //btCollisionShape* colShape = new btSphereShape(btScalar(1.));
    collisionShapes.push_back(colShape);
    
    /// Create Dynamic Objects
    btTransform startTransform;
    startTransform.setIdentity();
    
    btScalar	mass(1.f);
    
    //rigidbody is dynamic if and only if mass is non zero, otherwise static
    bool isDynamic = (mass != 0.f);
    
    btVector3 localInertia(0,0,0);
    if (isDynamic)
        colShape->calculateLocalInertia(mass,localInertia);
    
    startTransform.setOrigin(position);
    
    //using motionstate is recommended, it provides interpolation capabilities, and only synchronizes 'active' objects
    btDefaultMotionState* myMotionState = new btDefaultMotionState(startTransform);
    btRigidBody::btRigidBodyConstructionInfo rbInfo(mass,myMotionState,colShape,localInertia);
    btRigidBody* body = new btRigidBody(rbInfo);
    
    btVector3 initialForce(0,-1500,0);
    btVector3 relPos(0,0,0);
    //body->applyCentralForce(initialForce);
    body->applyForce(initialForce, relPos);
    //    body->applyImpulse(<#const btVector3 &impulse#>, <#const btVector3 &rel_pos#>)
    
    // impulse = force * delta_time
    //body->applyCentralImpulse(0,-2000,0);
    /*
     void	applyForce(const btVector3& force, const btVector3& rel_pos)
     {
     applyCentralForce(force);
     //http://en.wikipedia.org/wiki/Torque
     // boldsymbol{\tau} = \mathbf{r} \times \mathbf{F},
     applyTorque(rel_pos.cross(force*m_linearFactor));
     }
     
     */
    
    //Mathematically, torque is defined as the cross product of the lever-arm distance and force, which tends to produce rotation.
    //
    
    
    dynamicsWorld->addRigidBody(body);
}


-(void) initBulletPhysics {
    ///-----initialization_start-----
    
	///collision configuration contains default setup for memory, collision setup. Advanced users can create their own configuration.
    collisionConfiguration = new btDefaultCollisionConfiguration();
    
	///use the default collision dispatcher. For parallel processing you can use a diffent dispatcher (see Extras/BulletMultiThreaded)
    dispatcher = new	btCollisionDispatcher(collisionConfiguration);
    
	///btDbvtBroadphase is a good general purpose broadphase. You can also try out btAxis3Sweep.
    overlappingPairCache = new btDbvtBroadphase();
    
	///the default constraint solver. For parallel processing you can use a different solver (see Extras/BulletMultiThreaded)
    solver = new btSequentialImpulseConstraintSolver;
    
    dynamicsWorld = new btDiscreteDynamicsWorld(dispatcher,overlappingPairCache,solver,collisionConfiguration);
    
	dynamicsWorld->setGravity(btVector3(0,-10,0));
    
    ///create a few basic rigid bodies
	btCollisionShape* groundShape = new btBoxShape(btVector3(btScalar(50.),btScalar(50.),btScalar(50.)));
    
	//keep track of the shapes, we release memory at exit.
	//make sure to re-use collision shapes among rigid bodies whenever possible!
    //	btAlignedObjectArray<btCollisionShape*> collisionShapes;
    
	collisionShapes.push_back(groundShape);
    
	btTransform groundTransform;
	groundTransform.setIdentity();
	groundTransform.setOrigin(btVector3(0,-50,0));
    
	{
		btScalar mass(0.);
        
		//rigidbody is dynamic if and only if mass is non zero, otherwise static
		bool isDynamic = (mass != 0.f);
        
		btVector3 localInertia(0,0,0);
		if (isDynamic)
			groundShape->calculateLocalInertia(mass,localInertia);
        
		//using motionstate is recommended, it provides interpolation capabilities, and only synchronizes 'active' objects
		btDefaultMotionState* myMotionState = new btDefaultMotionState(groundTransform);
		btRigidBody::btRigidBodyConstructionInfo rbInfo(mass,myMotionState,groundShape,localInertia);
		btRigidBody* body = new btRigidBody(rbInfo);
        
        
        
		//add the body to the dynamics world
		dynamicsWorld->addRigidBody(body);
	}
    
    

        
         [self addBox:btVector3(2,10,0)];
         [self addBox:btVector3(2,15,0)];
         [self addBox:btVector3(2,19,0)];
         [self addBox:btVector3(5,10,0)];
         [self addBox:btVector3(1,10,0)];
         [self addBox:btVector3(1,10,0)];
         [self addBox:btVector3(1,22,0)];
         [self addBox:btVector3(1,25,3)];
         [self addBox:btVector3(1,27,1)];
         [self addBox:btVector3(1,35,2)];
         

}

-(void) unloadBulletPhysics {
    ///-----cleanup_start-----
    int i;
	//remove the rigidbodies from the dynamics world and delete them
	for (i=dynamicsWorld->getNumCollisionObjects()-1; i>=0 ;i--)
	{
		btCollisionObject* obj = dynamicsWorld->getCollisionObjectArray()[i];
		btRigidBody* body = btRigidBody::upcast(obj);
		if (body && body->getMotionState())
		{
			delete body->getMotionState();
		}
		dynamicsWorld->removeCollisionObject( obj );
		delete obj;
	}
    
	//delete collision shapes
	for (int j=0;j<collisionShapes.size();j++)
	{
		btCollisionShape* shape = collisionShapes[j];
		collisionShapes[j] = 0;
		delete shape;
	}
    
	//delete dynamics world
	delete dynamicsWorld;
    
	//delete solver
	delete solver;
    
	//delete broadphase
	delete overlappingPairCache;
    
	//delete dispatcher
	delete dispatcher;
    
	delete collisionConfiguration;
    
	//next line is optional: it will be cleared by the destructor when the array goes out of scope
	//collisionShapes.clear();
}

/**
 * Constructs the 3D scene.
 *
 * Adds 3D objects to the scene, loading a 3D 'hello, world' message
 * from a POD file, and creating the camera and light programatically.
 *
 * When adapting this template to your application, remove all of the content
 * of this method, and add your own to construct your 3D model scene.
 *
 * NOTE: The POD file used for the 'hello, world' message model is fairly large,
 * because converting a font to a mesh results in a LOT of triangles. When adapting
 * this template project for your own application, REMOVE the POD file 'hello-world.pod'
 * from the Resources folder of your project!!
 */
-(void) initializeScene {
    
    // init
    [self initBulletPhysics];

	// Create the camera, place it back a bit, and add it to the scene
	CC3Camera* cam = [CC3Camera nodeWithName: @"Camera"];
	cam.location = cc3v( 0.0, 0.0, 600.0 );
	[self addChild: cam];

	// Create a light, place it back and to the left at a specific
	// position (not just directional lighting), and add it to the scene
	CC3Light* lamp = [CC3Light nodeWithName: @"Lamp"];
	lamp.location = cc3v( -2.0, 0.0, 0.0 );
	lamp.isDirectionalOnly = NO;
	[cam addChild: lamp];

	// This is the simplest way to load a POD resource file and add the
	// nodes to the CC3Scene, if no customized resource subclass is needed.
    
    // collada model sample
    // convert with PVRGeoPOD
    //http://collada.org/owl/browse.php?sess=0&parent=120&expand=1&order=name
    
    
	//[self addContentFromPODFile: @"hello-world.pod"];
    [self addContentFromPODFile: @"cube.pod"];
    //[self addContentFromPODFile: @"duck.pod"];
    //[self addContentFromPODFile: @"bike.pod"];
	
	// Create OpenGL ES buffers for the vertex arrays to keep things fast and efficient,
	// and to save memory, release the vertex content in main memory because it is now redundant.
	[self createGLBuffers];
	[self releaseRedundantContent];
	
	// That's it! The scene is now constructed and is good to go.
	
	// If you encounter problems displaying your models, you can uncomment one or more of the
	// following lines to help you troubleshoot. You can also use these features on a single node,
	// or a structure of nodes. See the CC3Node notes for more explanation of these properties.
	// Also, the onOpen method below contains additional troubleshooting code you can comment
	// out to move the camera so that it will display the entire scene automatically.
	
	// Displays short descriptive text for each node (including class, node name & tag).
	// The text is displayed centered on the pivot point (origin) of the node.
//	self.shouldDrawAllDescriptors = YES;
	
	// Displays bounding boxes around those nodes with local content (eg- meshes).
//	self.shouldDrawAllLocalContentWireframeBoxes = YES;
	
	// Displays bounding boxes around all nodes. The bounding box for each node
	// will encompass its child nodes.
//	self.shouldDrawAllWireframeBoxes = YES;
	
	// If you encounter issues creating and adding nodes, or loading models from
	// files, the following line is used to log the full structure of the scene.
	LogInfo(@"The structure of this scene is: %@", [self structureDescription]);
	
	// ------------------------------------------

	// But to add some dynamism, we'll animate the 'hello, world' message
	// using a couple of cocos2d actions...
	
	// Fetch the 'hello, world' 3D text object that was loaded from the
	// POD file and start it rotating
	//CC3MeshNode* duck = (CC3MeshNode*)[self getNodeNamed: @"LOD3sp"];
    CC3MeshNode* mesh = (CC3MeshNode*)[self getNodeNamed: @"Box"];
//    CCActionInterval* partialRot = [CC3RotateBy actionWithDuration: 1.0 rotateBy: cc3v(0.0, 30.0, 0.0)];
//    [mesh runAction: [CCRepeatForever actionWithAction: partialRot]];
    

	//TODO
    // find vertexlist, normallist, indexlist from CC3MeshNode
    // add bullet mesh data  from CC3MeshNode
    // each timestep, reload vertexlist, normallist, indexlist from bullet object
    // set reloaded vertexlist, normallist, indexlist to CC3MeshNode



    /*
     
     
     objLoader *cube = [self loadObjFile:@"cube"];
     
     float maxx=5.0;
     float posx=CCRANDOM_MINUS1_1()*maxx;
     
     CC3MeshNode* aNode;
     aNode = [CC3BoxNode nodeWithName: @"Simple box"];
     CC3BoundingBox bBox;
     bBox.minimum = cc3v(-2.0, -2.0, -1.0);
     bBox.maximum = cc3v( 1.0,  1.0,  1.0);
     [aNode populateAsSolidBox: bBox];
     
         [aNode po];
     
     
     [aNode setLocation:cc3v(posx,0.0f,-5.0f)];
     
     CC3Material* material = [CC3Material materialWithName:@"iron"];
     //setColor: (ccColor3B) color
     
     [material setColor:ccc3(123,234,134)];
     
     aNode.material = material;
     [self addChild:aNode];
     
     
     
     
     #pragma mark Populating parametric triangles
     
     -(void) populateAsTriangle: (CC3Face) face
     withTexCoords: (ccTex2F*) tc
     andTessellation: (GLuint) divsPerSide {
     
     // Must have at least one division per side
     divsPerSide = MAX(divsPerSide, 1);
     
     // The fraction of each side that each division represents.
     // This is the barycentric coordinate division increment.
     GLfloat divFrac = 1.0f / divsPerSide;
     
     // Derive the normal. All vertices on the triangle will have the same normal.
     CC3Vector vtxNml = CC3FaceNormal(face);
     
     GLuint vertexCount = (divsPerSide + 2) * (divsPerSide + 1) / 2.0f;
     GLuint triangleCount = divsPerSide * divsPerSide;
     
     // Prepare the vertex content and allocate space for vertices and indices.
     [self ensureVertexContent];
     self.allocatedVertexCapacity = vertexCount;
     self.allocatedVertexIndexCapacity = (triangleCount * 3);
     
     GLuint vIdx = 0;
     GLuint iIdx = 0;
     
     // Denoting the three corners of the main triangle as c0, c1 & c2, and denoting the side
     // extending from c0 to c1 as s1, and the side extending from c0 to c2 as s2, we can work
     // in barycentric coordinates by starting at c0, iterating the divisions on the s2, and for
     // each divison on that side, iterating  the divisions on the side of the internal similar
     // triangle that is parallel to s1.
     for (GLuint i2 = 0; i2 <= divsPerSide; i2++) {
     
     // Calculate the barycentric weight for the current division along s2 and hold it constant
     // as we iterate through divisions along s1 of the resulting internal similar triangle.
     // The number of divisions on the side of the internal similar triangle is found by subtracting
     // the current division index of s2 from the total divisions per side.
     GLfloat bw2 = divFrac * i2;
     GLuint divsSimSide1 = divsPerSide - i2;
     for (GLuint i1 = 0; i1 <= divsSimSide1; i1++) {
     
     // Calculate the barycentric weight for the current division along s1 of the internal
     // similar triangle. The third barycentric weight falls out automatically.
     GLfloat bw1 = divFrac * i1;
     GLfloat bw0 = 1.0f - bw1 - bw2;
     CC3BarycentricWeights bcw = CC3BarycentricWeightsMake(bw0, bw1, bw2);
     
     // Vertex location from barycentric coordinates on the main face
     CC3Vector vtxLoc = CC3FaceLocationFromBarycentricWeights(face, bcw);
     [self setVertexLocation: vtxLoc at: vIdx];
     
     // Vertex normal is constant. Will do nothing if this mesh does not include normals.
     [self setVertexNormal: vtxNml at: vIdx];
     
     // Vertex texture coordinates derived from the barycentric coordinates and inverted vertically.
     // Will do nothing if this mesh does not include texture coordinates.
     GLfloat u = bw0 * tc[0].u + bw1 * tc[1].u + bw2 * tc[2].u;
     GLfloat v = bw0 * tc[0].v + bw1 * tc[1].v + bw2 * tc[2].v;
     [self setVertexTexCoord2F: cc3tc(u, (1.0f - v)) at: vIdx];
     
     // First tessellated triangle starting at the vertex and opening away from corner 0.
     if (i1 < divsSimSide1) {
     [self setVertexIndex: vIdx at: iIdx++];
     [self setVertexIndex: (vIdx + 1) at: iIdx++];
     [self setVertexIndex: (vIdx + divsSimSide1 + 1) at: iIdx++];
     }
     
     // Second tessellated triangle starting at the vertex and opening towards corner 0.
     if (i1 > 0 && i2 > 0) {
     [self setVertexIndex: vIdx at: iIdx++];
     [self setVertexIndex: (vIdx - 1) at: iIdx++];
     [self setVertexIndex: (vIdx - divsSimSide1 - 2) at: iIdx++];
     }
     
     vIdx++;		// Move on to the next vertex
     }
     }
     }

     

     
     */

    
    //CCActionInterval* partialRot = [CC3RotateBy actionWithDuration: 1.0 rotateBy: cc3v(0.0, 30.0, 0.0)];
	//[aNode runAction: [CCRepeatForever actionWithAction: partialRot]];
    

	// To make things a bit more appealing, set up a repeating up/down cycle to
	// change the color of the text from the original red to blue, and back again.
    /*
	GLfloat tintTime = 8.0f;
	ccColor3B startColor = helloTxt.color;
	ccColor3B endColor = { 50, 0, 200 };
	CCActionInterval* tintDown = [CCTintTo actionWithDuration: tintTime
														  red: endColor.r
														green: endColor.g
														 blue: endColor.b];
	CCActionInterval* tintUp = [CCTintTo actionWithDuration: tintTime
														red: startColor.r
													  green: startColor.g
													   blue: startColor.b];
	 CCActionInterval* tintCycle = [CCSequence actionOne: tintDown two: tintUp];
	[helloTxt runAction: [CCRepeatForever actionWithAction: tintCycle]];
     */
}


#pragma mark Updating custom activity

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities before
 * any changes are applied to the transformMatrix of the 3D nodes in the scene.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateBeforeTransform: (CC3NodeUpdatingVisitor*) visitor {
    int result = dynamicsWorld->stepSimulation(1.f/60.f,10);
    
    //NSLog(@"step = %d",result);

}

/**
 * This template method is invoked periodically whenever the 3D nodes are to be updated.
 *
 * This method provides your app with an opportunity to perform update activities after
 * the transformMatrix of the 3D nodes in the scen have been recalculated.
 *
 * For more info, read the notes of this method on CC3Node.
 */
-(void) updateAfterTransform: (CC3NodeUpdatingVisitor*) visitor {
	// If you have uncommented the moveWithDuration: invocation in the onOpen: method, you
	// can uncomment the following to track how the camera moves, where it ends up, and what
	// the camera's clipping distances are, in order to determine how to position and configure
	// the camera to view the entire scene.
//	LogDebug(@"Camera: %@", activeCamera.fullDescription);
    
    /*
    //print positions of all objects
    for (int j=dynamicsWorld->getNumCollisionObjects()-1; j>=0 ;j--)
    {
        btCollisionObject* obj = dynamicsWorld->getCollisionObjectArray()[j];
        btRigidBody* body = btRigidBody::upcast(obj);
        if (body && body->getMotionState())
        {
            btTransform trans;
            body->getMotionState()->getWorldTransform(trans);
//            [self getCubeFromVertices:obj vertexList:gCubeVertexList];
            
            //DISABLE_SIMULATION
            btBoxShape* boxShape = dynamic_cast<btBoxShape *>(obj->getCollisionShape());
            btRigidBody* body = btRigidBody::upcast(obj);
            if (!(body && body->getMotionState())) return;
            
            float invMass = body->getInvMass();
            //NSLog(@"getInvMass = %f", invMass);
            
            btVector3 vertex[8];
            int numofvertex = boxShape->getNumVertices();
            for(int i=0;i<numofvertex;i++){
                boxShape->getVertex(i, vertex[i]);
                
                 btVector3 vertexBasis;
                 boxShape->getVertex(i, vertexBasis);
                 vertex[i] = trans*vertexBasis;
                 
                //vertex[i];
                btVector3 vertexAfterTransform = trans*vertexBasis;
                
                //NSLog(@"vertex index = %d, pos = %f,%f,%f",i,vertexBasis.getX(),vertexBasis.getY(),vertexBasis.getZ());
                //NSLog(@"vertex index = %d, pos = %f,%f,%f",i,vertexAfterTransform.getX(),vertexAfterTransform.getY(),vertexAfterTransform.getZ());
            }

            
        }
        
    }
      */
}


#pragma mark Scene opening and closing

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene is first displayed.
 *
 * This method is a good place to invoke one of CC3Camera moveToShowAllOf:... family
 * of methods, used to cause the camera to automatically focus on and frame a particular
 * node, or the entire scene.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onOpen {

	// Uncomment this line to have the camera move to show the entire scene. This must be done
	// after the CC3Layer has been attached to the view, because this makes use of the camera
	// frustum and projection. If you uncomment this line, you might also want to uncomment the
	// LogDebug line in the updateAfterTransform: method to track how the camera moves, where
	// it ends up, and what the camera's clipping distances are, in order to determine how to
	// position and configure the camera to view the entire scene.
//	[self.activeCamera moveWithDuration: 3.0 toShowAllOf: self];

	// Uncomment this line to draw the bounding box of the scene.
//	self.shouldDrawWireframeBox = YES;
}

/**
 * Callback template method that is invoked automatically when the CC3Layer that
 * holds this scene has been removed from display.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) onClose {}


#pragma mark Handling touch events 

/**
 * This method is invoked from the CC3Layer whenever a touch event occurs, if that layer
 * has indicated that it is interested in receiving touch events, and is handling them.
 *
 * Override this method to handle touch events, or remove this method to make use of
 * the superclass behaviour of selecting 3D nodes on each touch-down event.
 *
 * This method is not invoked when gestures are used for user interaction. Your custom
 * CC3Layer processes gestures and invokes higher-level application-defined behaviour
 * on this customized CC3Scene subclass.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) touchEvent: (uint) touchType at: (CGPoint) touchPoint {}

/**
 * This callback template method is invoked automatically when a node has been picked
 * by the invocation of the pickNodeFromTapAt: or pickNodeFromTouchEvent:at: methods,
 * as a result of a touch event or tap gesture.
 *
 * Override this method to perform activities on 3D nodes that have been picked by the user.
 *
 * For more info, read the notes of this method on CC3Scene.
 */
-(void) nodeSelected: (CC3Node*) aNode byTouchEvent: (uint) touchType at: (CGPoint) touchPoint {}

@end


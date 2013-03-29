/**
 *  BulletCocos3DScene.h
 *  BulletCocos3D
 *
 *  Created by Dae-Yeong Kim on 13. 3. 28..
 *  Copyright __MyCompanyName__ 2013년. All rights reserved.
 */


#import "CC3Scene.h"
#include "btBulletDynamicsCommon.h"

/** A sample application-specific CC3Scene subclass.*/
@interface BulletCocos3DScene : CC3Scene {
    
    // BulletPhysics variables
    btDefaultCollisionConfiguration* collisionConfiguration;
	btCollisionDispatcher* dispatcher;
	btBroadphaseInterface* overlappingPairCache;
	btSequentialImpulseConstraintSolver* solver;
    btDiscreteDynamicsWorld* dynamicsWorld;
    
    btAlignedObjectArray<btCollisionShape*> collisionShapes;
    
}

@end

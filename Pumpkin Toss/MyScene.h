//
//  MyScene.h
//  Pumpkin Toss
//

//  Copyright (c) 2013 Riley Williams. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <CoreMotion/CoreMotion.h>

@interface MyScene : SKScene <SKPhysicsContactDelegate>

@property SKSpriteNode *turkey;

@property (strong) SKEmitterNode *leaves;

@property SKLabelNode *message;

@property int pumpkinsPopped;
@property NSTimeInterval lastTap;
@property NSTimeInterval lastReset;

@property (nonatomic, strong) CMMotionManager *motionManager;

int map(int a, int minA, int maxA, int minX, int maxX);

@end

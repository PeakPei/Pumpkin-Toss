//
//  MyScene.m
//  Pumpkin Toss
//
//  Created by Riley Williams on 11/12/13.
//  Copyright (c) 2013 Riley Williams. All rights reserved.
//

#import "MyScene.h"

#define MAX_TIMES 50
#define GRID_DEPTH 1

static const uint32_t pumpkinCategory	= 0x1 << 0;
static const uint32_t turkeyCategory	= 0x1 << 1;
static const uint32_t envCategory		= 0x1 << 2;

@implementation MyScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.motionManager = [[CMMotionManager alloc] init];
		self.motionManager.accelerometerUpdateInterval = 1/60.0f;
		[self.motionManager startAccelerometerUpdates];
        
        self.backgroundColor = [SKColor colorWithRed:1.0 green:0.35 blue:0.0 alpha:1.0];
        
        self.message = [SKLabelNode labelNodeWithFontNamed:@"Futura"];
        
        self.message.text = @"Tap to drop pumpkins!";
        self.message.fontSize = 30;
		self.message.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
		self.message.zPosition = .5;
        [self addChild:self.message];
		
		self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
		self.physicsBody.contactTestBitMask = envCategory;
		self.physicsBody.friction = .50;
		self.physicsWorld.gravity = CGVectorMake(0, -5.0);
		self.physicsWorld.contactDelegate = self;
		
		self.turkey = [SKSpriteNode spriteNodeWithImageNamed:@"Turkey"];
		self.turkey.xScale = -.25;
		self.turkey.yScale = .25;
		self.turkey.position = CGPointMake(50, 50);
		self.turkey.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(.9*self.turkey.size.width, .9*self.turkey.size.height)];
		self.turkey.physicsBody.affectedByGravity = YES;
		self.turkey.physicsBody.categoryBitMask = turkeyCategory;
		self.turkey.physicsBody.contactTestBitMask = pumpkinCategory | envCategory;
		self.turkey.physicsBody.collisionBitMask = envCategory;
		self.turkey.physicsBody.allowsRotation = NO;
		self.turkey.physicsBody.restitution = .6;
		self.turkey.physicsBody.friction = .4;
		self.turkey.zPosition = 1;
		[self addChild:self.turkey];
		self.scaleMultiplier = 1;
		
		self.wind = malloc(sizeof(CGVector)*16*9*GRID_DEPTH);
		
		self.pumpkinsPopped = 0;
		NSTimer *t = [NSTimer timerWithTimeInterval:.5 target:self selector:@selector(recalculateLeafRate) userInfo:Nil repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:t forMode:NSRunLoopCommonModes];
	}
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
	self.lastTap = [NSDate timeIntervalSinceReferenceDate];
    if (self.leaves == nil) {
		self.leaves = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Leaves" ofType:@"sks"]];
		self.leaves.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame)+20);
		self.leaves.particlePositionRange = CGVectorMake(self.frame.size.width, 0);
		self.leaves.zPosition = -1;
		[self addChild:self.leaves];
	}
	
    for (UITouch *touch in touches) {
		[self addPumpkinAtLocation:[touch locationInNode:self]];
    }
}

-(void)recalculateLeafRate {
	static int i = 0;
	if (([NSDate timeIntervalSinceReferenceDate] - self.lastTap) < 1) {
		if (self.message.alpha == 1.0) {
			SKAction *fadeAway = [SKAction fadeAlphaTo:0.0 duration:.5];
			fadeAway.timingMode = SKActionTimingEaseIn;
			[self.message runAction:fadeAway];
		}
	} else {
		if (([NSDate timeIntervalSinceReferenceDate] - self.lastTap) > 12 && self.message.alpha == 0) {
			SKAction *fadeAway = [SKAction fadeAlphaTo:1.0 duration:.5];
			fadeAway.timingMode = SKActionTimingEaseIn;
			[self.message runAction:fadeAway];
		}
	}
	
	self.leaves.particleBirthRate = 2 * self.pumpkinsPopped + .1;
	if (i++ >= 1) {
		i = 0;
		self.pumpkinsPopped = 0;
	}
	NSLog(@"%f",self.leaves.particleBirthRate);
}

-(void)addPumpkinAtLocation:(CGPoint)location {
	SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Pumpkin"];
	sprite.position = location;
	int size = arc4random_uniform(20)+30;
	sprite.size = CGSizeMake(size, size);
	sprite.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:.42f*size];
	sprite.physicsBody.mass = .005*size*size;
	sprite.physicsBody.restitution = .975;
	sprite.physicsBody.friction = .7;
	int speed = arc4random_uniform(100)+25;
	float angle = arc4random_uniform(180)*M_PI/180.0f;
	sprite.physicsBody.velocity = CGVectorMake(speed*cosf(angle), speed*sinf(angle));
	sprite.physicsBody.categoryBitMask = pumpkinCategory;
	sprite.physicsBody.contactTestBitMask = pumpkinCategory;
	sprite.zPosition = .75;
	sprite.physicsBody.angularVelocity = 3*M_PI*(arc4random_uniform(1024)/512.0f-1);
	[self addChild:sprite];
	
}


-(void)didBeginContact:(SKPhysicsContact *)contact {
	if (contact.bodyA.categoryBitMask == pumpkinCategory && contact.bodyB.categoryBitMask == pumpkinCategory) {
		float impPerMassA = contact.collisionImpulse / contact.bodyA.mass;
		float impPerMassB = contact.collisionImpulse / contact.bodyB.mass;
		if (impPerMassA > 600) {
			SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Break" ofType:@"sks"]];
			explosion.position = contact.bodyB.node.position;
			[self addChild:explosion];
			[contact.bodyA.node removeFromParent];
			self.pumpkinsPopped++;
		}
		if (impPerMassB > 600) {
			SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Break" ofType:@"sks"]];
			explosion.position = contact.bodyB.node.position;
			[self addChild:explosion];
			[contact.bodyB.node removeFromParent];
			self.pumpkinsPopped++;
		}
	} else if ((contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask) == (pumpkinCategory | turkeyCategory)) {
		SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"Break" ofType:@"sks"]];
		explosion.position = contact.contactPoint;
		[self addChild:explosion];
		self.pumpkinsPopped++;
		if (contact.bodyA.categoryBitMask == turkeyCategory)
			[contact.bodyB.node removeFromParent];
		else
			[contact.bodyA.node removeFromParent];
	}
}

-(void)update:(CFTimeInterval)currentTime {
	
	float xAccl = self.motionManager.accelerometerData.acceleration.y;
	//float yAccl = -self.motionManager.accelerometerData.acceleration.x;
	
	self.physicsWorld.gravity = CGVectorMake(5*xAccl,-sqrt(25-5*xAccl));
	
	CGPoint turkey = self.turkey.position;
	float distance = 10000;
	CGPoint target = CGPointMake(self.frame.size.width/2, 100);
	for (SKSpriteNode *node in self.children) {
		if (node.physicsBody.categoryBitMask == pumpkinCategory) {
			float di = turkey.x-node.position.x;
			if (fabs(di) < fabs(distance)) {
				distance = di;
				target = node.position;
			}
			//int x = map(node.position.x, 0, self.frame.size.width, 0, 16);
		}
	}
	if (distance < 10000 && self.turkey.position.y < 60) {
		[self.turkey.physicsBody applyForce:CGVectorMake(-distance, 0)];
	}
	if (self.turkey.physicsBody.velocity.dx >= 0) {
		self.turkey.xScale =-.25;
	} else {
		self.turkey.xScale = .25;
	}
	if (distance < 80 && self.turkey.position.y < 31 && target.y > 80) {
		self.turkey.physicsBody.velocity = CGVectorMake(self.turkey.physicsBody.velocity.dx*.8,380);
	}
	NSArray *particles = self.leaves.children;
	NSLog(@"%@",particles);
}

int map(int a, int minA, int maxA, int minX, int maxX) {
	return a*(maxX-minX)/(maxA-minA);
}

@end

//
//  SLPAppDelegate.h
//  eFixer
//
//  Created by Stephen La Pierre on 1/8/13.
//  Copyright (c) 2013 Stephen La Pierre. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SLPAppDelegate : NSObject <NSApplicationDelegate> {
    NSString *fileDate;
	IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField *ePubDirectory;
	IBOutlet NSButton *getDirButton;
	IBOutlet NSButton *cleanButton;
    IBOutlet NSButton *stripCoverBox;
    IBOutlet NSTextField *saveCoverFile;
    IBOutlet NSButton *coverSave;
    NSInteger checked;
    NSInteger changed;
    NSInteger wasbad;
}

- (IBAction)selectFolder:(id)sender;
- (IBAction)selectSaveToFolder:(id)sender;
- (IBAction)cleanFiles:(id)sender;
- (IBAction)enableSaveCovers:(id)sender;

-(void)goBusy;
-(void)goFree;

@property (assign) IBOutlet NSWindow *window;
@property(readwrite, strong) NSString *fileDate;
@property (assign) NSInteger checked;
@property (assign) NSInteger changed;
@property (assign) NSInteger wasbad;
@property(readwrite, assign) BOOL doStripCover;

@end

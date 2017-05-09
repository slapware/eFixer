//
//  SLPAppDelegate.m
//  eFixer
//
//  Created by Stephen La Pierre on 1/8/13.
//  Copyright (c) 2013 Stephen La Pierre. All rights reserved.
//  Made to check the epub OPF for correct ISBN

#import "SLPAppDelegate.h"
#import "NSString+slapadds.h"
#import "OpfChecker.h"

@implementation SLPAppDelegate

@synthesize fileDate;
@synthesize checked;
@synthesize changed;
@synthesize wasbad;
@synthesize doStripCover;

#pragma mark -
#pragma mark Standard functions
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.checked = 0;
    self.changed = 0;
    self.wasbad = 0;
    self.doStripCover = NO;
    [coverSave setEnabled:NO];
    [saveCoverFile setEditable:NO];
}
// ----------------------------------------------------------------------------
// applicationShouldTerminateAfterLastWindowClosed ---
// ----------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}
#pragma mark -
#pragma mark Folder selection
// ----------------------------------------------------------------------------
// selectFolder ---
// ----------------------------------------------------------------------------
- (IBAction)selectFolder:(id)sender
{
    NSInteger result;
    NSArray *fileTypes = @[@"epub",@"pdf"];
 	NSOpenPanel * panel = [NSOpenPanel openPanel];
	
	
	[panel setPrompt:@"Choose folder"]; // Should be localized
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
    [panel setAllowedFileTypes:fileTypes];
    [panel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
    
    [panel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
    
    result = [panel runModal];
    //    if ([panel runModal] == NSFileHandlingPanelOKButton)
	if (result == NSOKButton)
    {
        // get the urls
        NSArray *selectedFolder = [panel URLs];
		NSURL *readFrom = selectedFolder[0];
		NSString *readPath = [readFrom path];
        //		[self makeXmlData:[readFrom relativePath]];
		[ePubDirectory setStringValue:readPath];
        self.checked = 0;
        self.wasbad = 0;
        self.changed = 0;
    }
    else
    {
        // cancel button was clicked
		return;
    }
}

- (IBAction)enableSaveCovers:(id)sender;
{
    // NOTE: strip covers check
    if ([stripCoverBox state] == NSOnState) {
        self.doStripCover = YES;
        [coverSave setEnabled:YES];
        [saveCoverFile setEditable:YES];
    }
    else
    {
        self.doStripCover = NO;
        [coverSave setEnabled:NO];
        [saveCoverFile setEditable:NO];
    }
    
}
#pragma mark -
#pragma mark The main clean function
// -------------------------------------------------------------------------------
//  cleanFiles --- 
// -------------------------------------------------------------------------------
- (IBAction)cleanFiles:(id)sender;
{
    if([[ePubDirectory stringValue] length] < 1)
    {
        NSInteger alertReturn = NSRunAlertPanel(@"Invalid location", @"Please select a valid ePub directory." , @"Cancel", nil, nil);
        if (alertReturn == NSAlertDefaultReturn)
            return;
    }
    // NOTE: strip covers check
    if ([stripCoverBox state] == NSOnState) {
        self.doStripCover = YES;
//        NSString *saveCoverTo = [saveCoverFile stringValue];
        if ([[saveCoverFile stringValue] length] < 3) {
            NSInteger alertReturn = NSRunAlertPanel(@"Invalid Location", @"Please select a valid location for covers." , @"Cancel", nil, nil);
            if (alertReturn == NSAlertDefaultReturn)
                return;  
        }
    }
    else
    {
        self.doStripCover = NO;
    }
    [self goBusy];
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MM-dd-YY_HH_mm_ss_"];
    self.fileDate = [dateFormatter stringFromDate:today];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0]; // Get documents directory
    NSDirectoryEnumerator*	e = [[NSFileManager defaultManager] enumeratorAtPath:[ePubDirectory stringValue]];
    for (NSString*	file in e)
    {
        if (NSOrderedSame == [[file pathExtension] caseInsensitiveCompare:@"epub"])
        {
            NSString *fileToCheck = [NSString stringWithFormat:@"%@/%@", [ePubDirectory stringValue], file];
            @autoreleasepool {
                NSString* myresponce;
                self.checked++;
                OpfChecker *opfFixer = [[OpfChecker alloc] init];
                if ([stripCoverBox state] == NSOnState) {
                    opfFixer.stripCover = YES;
                    opfFixer.coverLocation = [saveCoverFile stringValue];
                }
                opfFixer.input = fileToCheck;
                [opfFixer openOPF];
                

//                OpfChecker *opfFixer = [[OpfChecker alloc] initWithFile:fileToCheck];
                if ((opfFixer.didModify) && (opfFixer.canRead))
                {
                    if (opfFixer.wasWrong)
                    {
                        myresponce = [NSString stringWithFormat:@"%@ was modified as wrong with %@\n", fileToCheck, opfFixer.oldident];
                        self.wasbad++;
                    }
                    else
                    {
                        myresponce = [NSString stringWithFormat:@"%@ was modified from %@\n", fileToCheck, opfFixer.oldident];
                    }
                    self.changed++;
                }
                else
                {
                    if ((opfFixer.notFound == YES) && (opfFixer.canRead) )
                    {
                        myresponce = [NSString stringWithFormat:@"%@ dc:identifier was NOT found\n", fileToCheck];
                    }
                    else
                    {
                        myresponce = [NSString stringWithFormat:@"%@ was not modified\n", fileToCheck];
                    }
                    if ((!opfFixer.didModify) && (!opfFixer.canRead))
                    {
                        myresponce = [NSString stringWithFormat:@"%@ had issue with zip directory, unchecked\n", fileToCheck];
                    self.wasbad++;
                    }
                }
                
                BOOL succeed = [myresponce appendToFile:[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_fixer.log", self.fileDate]] encoding:NSUTF8StringEncoding];
                if (!succeed){
                    // Handle error here
                    NSRunAlertPanel(@"File save Error", @"Could not save assigment file", nil, nil, nil);
            } 
          } // @autoreleasepool
        }
    } // for (NSString*	file in e)
    [self goFree];
}
// ----------------------------------------------------------------------------
// selectFolder ---
// ----------------------------------------------------------------------------
- (IBAction)selectSaveToFolder:(id)sender
{
    NSInteger result;
    NSArray *fileTypes = @[@"epub", @"jpg"];
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    
    
    [panel setPrompt:@"Choose folder"]; // Should be localized
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowedFileTypes:fileTypes];
    [panel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
    
    [panel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
    
    result = [panel runModal];
    if (result == NSOKButton)
    {
        // get the urls
        NSArray *selectedFolder = [panel URLs];
        NSURL *saveTo = selectedFolder[0];
        NSString *savePath = [saveTo path];
        [saveCoverFile setStringValue:savePath];
    }
    else
    {
        // cancel button was clicked
        return;
    }
}

#pragma mark -
#pragma mark UI display feedback
// -------------------------------------------------------------------------------
//  goBusy --- 
// -------------------------------------------------------------------------------
-(void)goBusy
{
    [getDirButton setEnabled:NO];
    [cleanButton setEnabled:NO];
    [progress startAnimation:nil];
}
// -------------------------------------------------------------------------------
//  goFree --- 
// -------------------------------------------------------------------------------
-(void)goFree
{
    [progress stopAnimation:nil];
    [getDirButton setEnabled:YES];
	[cleanButton setEnabled:YES];
}

@end

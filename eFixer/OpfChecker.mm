//
//  OpfChecker.m
//  HCePub
//
//  Created by Stephen La Pierre on 9/17/12.
//
//

#import "OpfChecker.h"
#import "CkoZip.h"
#import "CkoZipEntry.h"

@implementation OpfChecker
@synthesize input;
@synthesize isDone, canRead;
@synthesize errorMessage;
@synthesize didModify;
@synthesize wasWrong;
@synthesize notFound;
@synthesize oldident;
@synthesize stripCover;
@synthesize coverLocation;
// -------------------------------------------------------------------------------
//  initWithFile --- 
// -------------------------------------------------------------------------------
- (id) initWithFile: (NSString*)pInput
{
    self = [super init];
    if (self != nil) {
        self.input = pInput;
        self.didModify = NO;
        self.wasWrong = NO;
        self.notFound = NO;
        self.stripCover = NO;
        [self openOPF];
    }
    return self;
}

-(id)init
{
    if (self = [super init])
    {
        // Initialization code here
        self.didModify = NO;
        self.wasWrong = NO;
        self.notFound = NO;
    }
    return self;
}

-(void)cleanUp;
{
//    NSXMLDocument = nil;
}
// -------------------------------------------------------------------------------
//  openOPF --- 
// -------------------------------------------------------------------------------
-(bool) openOPF
{
//    NSError *err = nil;
    BOOL success;
    @autoreleasepool {
    NSMutableString *strOutput = [NSMutableString stringWithCapacity:1000];

    CkoZip *zip = [[CkoZip alloc] init];
    success = [zip UnlockComponent: @"HARPERZIP_MbqLJJeWkRyu"];
    if (success != YES) {
        [strOutput appendString: zip.LastErrorText];
        [strOutput appendString: @"\n"];
        self.errorMessage = strOutput;
        return NO;
    }
    zip.VerboseLogging = YES;
    success = [zip OpenZip: self.input];
    if (success != YES) {
        [strOutput appendString: zip.LastErrorText];
        [strOutput appendString: @"\n"];
        self.errorMessage = strOutput;
        self.canRead = NO;
        return self.canRead;
    }
    // find and store cover image
    NSString *newIsbn = [self newIdent:self.input];
    BOOL saveImage = NO;
    CkoZipEntry *coverEntry;
    NSString *pattern;
    NSString *coverSearchString = @"*over.j*";
        pattern = coverSearchString;
        coverEntry = [zip FirstMatchingEntry:coverSearchString];
        if (coverEntry == nil) {
            NSString *coverSearchString2 = [NSString stringWithFormat:@"%@*.j*", [self newIdent:self.input]];
            coverEntry = [zip FirstMatchingEntry:coverSearchString2];
            if (coverEntry == nil) {
                saveImage = NO;
            }
            else {
                saveImage = YES;
                pattern = coverSearchString2;
            }
        }
        else {
            saveImage = YES;
        }
        if(saveImage) {
            [zip UnzipMatchingInto:self.coverLocation pattern:pattern verbose:NO];
//            NSString *newPath = [[oldPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newIsbn];
//            [[NSFileManager defaultManager] movePath:oldPath toPath:newPath handler:nil];
        }
//    NSString *newIsbn = [self newIdent:self.input];
    // multimedia list to avoid
    CkoZipEntry *entry;
    NSString *searchString = @".opf";    
        entry = [zip FirstMatchingEntry:searchString];
        if (entry == nil) {
            [zip CloseZip];
            return NO;
        }
        if (entry.IsDirectory == NO) {
            NSRange suffixRange = [[entry FileName] rangeOfString:searchString
                                  options:(NSAnchoredSearch | NSCaseInsensitiveSearch | NSBackwardsSearch)];
            if (suffixRange.length > 0)
            {
                NSString* opfData = [entry UnzipToString:0 srcCharset:@"utf-8"];
                NSData *newOpf = [self checkOPF:opfData newIsbn:newIsbn];
                if (self.didModify) {
                // NOTE: Important to use NSUTF8StringEncoding and NOT NSASCIIStringEncoding as chars > 127 present
                    NSString *newEntry = [[NSString alloc] initWithData:newOpf encoding:NSUTF8StringEncoding]; 
                    // NOTE: change line endings from unix to dos.
                    newEntry = [newEntry stringByReplacingOccurrencesOfString:@"&#169;" withString:@""];
                    newEntry = [newEntry stringByReplacingOccurrencesOfString:@"\n" withString:@"\r\n"];
//                    [entry setTextFlag:YES];
                    success = [entry ReplaceString:newEntry charset:@"utf-8"];
                    if (success != YES) {
                        [strOutput appendString: entry.LastErrorText];
                        [strOutput appendString: @"\n"];
                        self.errorMessage = strOutput;
                        return NO;
                    }
                    else
                    {
                     success = YES;
//                    [zip WriteZip];
                    }
                }
                
            } // if (suffixRange.length > 0)
            
        } // if (entry.IsDirectory == NO)

    if (self.didModify) {
//        [zip CloseZip];
        [zip WriteZipAndClose];
    }
    else
    {
        [zip CloseZip];
    }
//    self.canRead = YES;
    } // @autoreleasepool
    return self.canRead;
}
// -------------------------------------------------------------------------------
//  newIdent --- 
// -------------------------------------------------------------------------------
-(NSString*)newIdent:(NSString *)pFile
{
    NSString *newIsbn;
    NSRange rangeOfIsbn = [pFile rangeOfString:@"978"];
    
    if(rangeOfIsbn.location == NSNotFound)
    {
        // error condition — the text '<a href' wasn't in 'string'
        return newIsbn;;
    }
    else
    {
        newIsbn = [pFile substringWithRange:NSMakeRange(rangeOfIsbn.location, 13)];
    }
    return newIsbn;;    
}
// -------------------------------------------------------------------------------
//  checkOPF --- 
// -------------------------------------------------------------------------------
-(NSData*)checkOPF:(NSString *)pOpf newIsbn:(NSString*)newIdent
{
    NSError *err = nil;
    self.oldident = @"";
    // NOTE: NSXMLNodeCompactEmptyElement required for epub short tag support.
    xmlDoc = [[NSXMLDocument alloc] initWithXMLString:pOpf options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA | NSXMLNodeCompactEmptyElement) error:&err];
    
    if( xmlDoc == nil )
    {
        // in previous attempt, it failed creating XMLDocument because it
        // was malformed.
        xmlDoc = [[NSXMLDocument alloc] initWithXMLString:pOpf options:NSXMLDocumentTidyXML error:&err];
    }
    if( xmlDoc == nil)
    {
        NSLog( @"Error occurred while reading epub XML document.");
        if(err)
        {
            self.canRead = NO;
        }
    }
    else
    {
        // get all of the children from the root node into an array
        NSArray *children = [[xmlDoc rootElement] children];
        NSUInteger i, count = [children count];

        //loop through each child
        for (i=0; i < count; i++) {
            NSXMLElement *child = [children objectAtIndex:i];
            
            //check to see if the child node is of 'metadata' type
            if (([child.name isEqual:@"metadata"]) || ([child.name isEqual:@"opf:metadata"])) {
                    NSXMLNode *nsNamespaceNode;
                    nsNamespaceNode = [child namespaceForPrefix:@"dc"];
                    NSArray *idents = [child elementsForLocalName: @"identifier" URI:[nsNamespaceNode stringValue]];
                    // NOTE: was fixed 17/12/2013
                    if (([idents count] == 0 )  || (idents == nil) ) {
                        idents = [xmlDoc nodesForXPath:@".//opf:package/opf:metadata/dc:identifier" error:&err];
                    }
                    if (([idents count] == 0 )  || (idents == nil) ) {
                        idents = [xmlDoc nodesForXPath:@".//package/metadata/dc:identifier" error:&err];
                    }
                    if (([idents count] == 0 )  || (idents == nil) ) {
                        idents = [xmlDoc nodesForXPath:@".//package/opf:metadata/dc:identifier" error:&err];
                    }
                    if ([idents count] > 0) {
                        NSXMLNode *dcidentifier = [idents objectAtIndex:0];
                        NSString *oldvalue =  [dcidentifier objectValue];
                        if ([oldvalue length] == 0) {
                            oldvalue = @"No value";
                        }
                        self.oldident = oldvalue;
                        // NOTE: Compare found ISBN with one taken from file name of epub
                        if (([oldvalue length] != 13) || ([oldvalue hasPrefix:@"978"] == NO) || ([oldvalue isEqualToString:newIdent] == NO)) {
                            if ([newIdent length] == 13) {
                                [dcidentifier setStringValue:newIdent];
                                self.didModify = YES;
                                oldvalue = [oldvalue stringByReplacingOccurrencesOfString:@"-" withString:@""];
                                if ([oldvalue isEqualToString: newIdent] == NO) {
                                    self.wasWrong = YES;
                                }
                                else
                                {
                                    self.wasWrong = NO;
                                }
                            }
                            else
                            {
                                // newIdent no good
                                self.didModify = NO;
                            }
                        }
                    }
                    else {
                        // dc:identifier not found
                        self.notFound = YES;
                        self.didModify = NO;
                    }
            } // if (([child.name isEqual:@"metadata"]) || ([child.name isEqual:@"opf:metadata"]))
        } // for (i=0; i < count; i++)
    }
    err = nil;
    return [xmlDoc XMLData];
}

@end
    

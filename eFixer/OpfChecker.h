//
//  OpfChecker.h
//  HCePub
//
//  Created by Stephen La Pierre on 9/17/12.
//  Fix ISBN in dc:identifier if not correct or missing.
//

#import <Foundation/Foundation.h>

@interface OpfChecker : NSObject
{
    NSXMLDocument *xmlDoc;
    BOOL canRead;
    BOOL isDone;
    BOOL didModify;
    BOOL wasWrong;
    BOOL notFound;
    NSString *input;
    NSString *errorMessage;
    NSString *oldident;
}

@property(readwrite, strong) NSString *input;
@property (readwrite) BOOL isDone;
@property (readwrite) BOOL canRead;
@property (readwrite) BOOL didModify;
@property (readwrite) BOOL wasWrong;
@property (readwrite) BOOL notFound;
@property (readwrite) BOOL stripCover;
@property(readwrite, strong) NSString *errorMessage;
@property(readwrite, strong) NSString *oldident;
@property(readwrite, strong) NSString *coverLocation;

- (id)init;
- (id) initWithFile: (NSString*)pInput;
-(bool) openOPF;
-(NSString*)newIdent:(NSString *)pFile;
-(NSData*)checkOPF:(NSString *)pOpf newIsbn:(NSString*)newIdent;
-(void)cleanUp;

@end

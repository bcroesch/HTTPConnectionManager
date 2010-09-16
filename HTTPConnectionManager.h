//
//Copyright (c) 2004-2010 Benjamin Roesch
//
//Permission is hereby granted, free of charge, to any person obtaining
//a copy of this software and associated documentation files (the
//															"Software"), to deal in the Software without restriction, including
//without limitation the rights to use, copy, modify, merge, publish,
//distribute, sublicense, and/or sell copies of the Software, and to
//permit persons to whom the Software is furnished to do so, subject to
//the following conditions:
//
//The above copyright notice and this permission notice shall be
//included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  HTTPConnectionManager.h
//
//	This custom class to manage the lifecycle of a NSURLConnection. It has one main function, makeRequestWithUrlString,
//  which takes parameters for the url, http method and parameters. It also takes arguments for a responder, which is
//  the object which owns (and responds to) the http call. Lastly, it takes two selectors, one for a success handler
//  and one for an error handler. The responder must implement these two responder methods, and both methods must take
//  two arguments. The first argument will always be the HTTPConnectionManager object, so that it can be released.
//  The second argument for the success handler is a NSMutableData with the data payload from the http call.
//  The second argument for the error handler is the NSError from the failed connection.
//

#import <Foundation/Foundation.h>

typedef enum {
	HTTPConnectionManagerErrorNoContent = 0,
	HTTPConnectionManagerErrorNotFound,
	HTTPConnectionManagerErrorNoInternetConnection,
	HTTPConnectionManagerErrorForbidden
} HTTPConnectionManagerError;

@interface HTTPConnectionManager : NSObject {
	id<NSObject> owner;
	SEL successHandler;
	SEL errorHandler;
	
	NSURLConnection * connection; 
	NSMutableURLRequest * request;
	
	NSMutableData *receivedData;
	
}

@property (retain) id<NSObject> owner;
@property (nonatomic) SEL successHandler;
@property (nonatomic) SEL errorHandler;

@property (nonatomic, retain) NSURLConnection * connection;
@property (nonatomic, retain) NSMutableURLRequest *request;

@property (nonatomic, retain) NSMutableData *receivedData;

-(void)makeRequestWithUrlString:(NSString *) urlString method:(NSString *) methodString parameters:(NSString*)parameterString responder:(id)responder successHandler:(SEL)sh errorHandler:(SEL)eh;
-(void)cancelCurrentRequest;
+(BOOL)hasInternetConnection;

@end

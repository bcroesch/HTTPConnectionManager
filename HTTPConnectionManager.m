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

#import "HTTPConnectionManager.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

@implementation HTTPConnectionManager

@synthesize owner;
@synthesize connection;
@synthesize request;
@synthesize receivedData;
@synthesize successHandler, errorHandler;

/*
-(id)init{
	if (self = [super init]) {
		[self retain];
	}
	return self;
}
*/

-(void)makeRequestWithUrlString:(NSString *) urlString method:(NSString *) methodString parameters:(NSString*)parameterString responder:(id)responder successHandler:(SEL)sh errorHandler:(SEL)eh {
	
	if (![HTTPConnectionManager hasInternetConnection]) {
		NSError *error = [NSError errorWithDomain:@"HTTPConnectionManager" code:HTTPConnectionManagerErrorNoInternetConnection userInfo:nil];
		[owner performSelector:errorHandler withObject:self withObject:error];
		//do not put anything after here. the callback to owner must be the last thing called, so that the owner can release this object
		return;
	}
	
	self.owner = responder;
	self.successHandler = sh;
	self.errorHandler = eh;
	NSURL *url;
	
	if([methodString isEqualToString:@"POST"]){
		url = [NSURL URLWithString:urlString];
		
		request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];  
		
		[request setHTTPBody:[parameterString dataUsingEncoding:NSUTF8StringEncoding]]; 
		
		DebugLog(@"Making POST to: %@ \n with data: %@", urlString, parameterString);
	}
	else if([methodString isEqualToString:@"GET"]){
		if (![parameterString isEqualToString:@""] && parameterString != nil) {
			urlString = [urlString stringByAppendingFormat:@"?%@", parameterString];
		}

		url = [NSURL URLWithString:urlString];
		
		request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30]; 
		
		DebugLog(@"Making GET to: %@", urlString);
	}
	
	// Override setAllowsAnyHTTPSCertificate for homemade SSL cert otherwise popup a error when use home made ssl
	//[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[[request URL] host]];
	
	[request setHTTPMethod:methodString];
 	
	
	// Create the connection 
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self]; 
	[request release];
	
	// Check the connection object 
	if(connection) 
	{ 		
		receivedData=[[NSMutableData data] retain]; 
	} 
	else{
		//connection failed
		[owner performSelector:errorHandler withObject:self withObject:nil];
		//do not put anything after here. the callback to owner must be the last thing called, so that the owner can release this object
		return;
	}
}

-(void)cancelCurrentRequest{
	[connection cancel];
	[connection release];
}

/**
 Called when the connection receives some response.  Set the receivedData length to 0 and wait until we 
 receive actual data.
 @param connection The connection that received the response.
 @param response The response received by the connection.
 */
- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response{
	[receivedData setLength:0];
	
	if ([response statusCode] == 204) {
		NSError *error = [[[NSError alloc] initWithDomain:@"HTTPConnectionManagerError" code:HTTPConnectionManagerErrorNoContent userInfo:nil] autorelease];
		
		[connection cancel];
		if(connection != nil){
			[connection release];
			connection = nil;
		}
		[owner performSelector:errorHandler withObject:self withObject:error];
		//do not put anything after here. the callback to owner must be the last thing called, so that the owner can release this object
		return;
	}
	else if([response statusCode] == 403){
		NSError *error = [[[NSError alloc] initWithDomain:@"HTTPConnectionManagerError" code:HTTPConnectionManagerErrorNotFound userInfo:nil] autorelease];
		
		[connection cancel];
		if(connection != nil){
			[connection release];
			connection = nil;
		}
		
		[owner performSelector:errorHandler withObject:self withObject:error];
		//do not put anything after here. the callback to owner must be the last thing called, so that the owner can release this object
		return;
	}
	else if([response statusCode] == 404){
		NSError *error = [[[NSError alloc] initWithDomain:@"HTTPConnectionManagerError" code:HTTPConnectionManagerErrorNotFound userInfo:nil] autorelease];
		
		[connection cancel];
		if(connection != nil){
			[connection release];
			connection = nil;
		}
		
		[owner performSelector:errorHandler withObject:self withObject:error];
		//do not put anything after here. the callback to owner must be the last thing called, so that the owner can release this object
		return;
	}
	
}

/**
 Called when the connection receives data. We append this data to any data that we have received so far.
 
 @param connection The connection that received the data.
 @param data The data received by the connection.
 */
- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data{
	
    [receivedData appendData:data];
}

/**
 Called when the connection fails. If this happens, we release the connection and inform the delegate that our
 connection failed.
 
 @param connection The connection that failed.
 @param error The error produced by the connection.
 */
- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error{
	
    // release the connection, and the data object
	if(connection != nil){
		[connection release];
		connection = nil;
	}
    [receivedData release];
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@ %@", [error localizedDescription],  
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey],
		  [error domain]);
	
	[owner performSelector:errorHandler withObject:self withObject:error];
	//do not put anything after here. the callback to owner must be the last thing called, so that the owner can release this object
	return;
}


/**
 Called when the connection completes loading the response. Informs the delegate that the response was received
 and passes it the received data.
 @param connection The connection that finished loading.
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)conn{
	//DebugLog([[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding]);
	//give the received data to our delegate so that it can act on it
	[owner performSelector:successHandler withObject:self withObject:receivedData];
	//do not put anything after here. the callback to owner must be the last thing called, so that the owner can release this object
	return;
}

+(BOOL)hasInternetConnection{
	
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
	
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
	
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
	
    if (!didRetrieveFlags)
    {
        printf("Error. Could not recover network reachability flags\n");
        return 0;
    }
	
    return flags & kSCNetworkFlagsReachable;
}


/**
 Releases any resources allocated or retained by this class.
 */
- (void)dealloc {
	[owner release];
	
	if(receivedData != nil)
		[receivedData release];
	
	if(connection != nil){
		[connection release];
		connection = nil;
	}
	
	//if(request != nil)
	//	[request release];
	
	//[url release];
	//[protocol release];
	
    [super dealloc];
}

@end

#import <Foundation/Foundation.h>

@interface NSFileManager (Ringly)

/**
 *  Returns the documents file path.
 */
@property (nonnull, nonatomic, readonly) NSString *rly_documentsPath;

/**
 *  Returns the caches file path.
 */
@property (nonnull, nonatomic, readonly) NSString *rly_cachesPath;

/**
 *  Returns the documents file URL.
 */
@property (nonnull, nonatomic, readonly) NSURL *rly_documentsURL;

/**
 *  Returns the caches file URL.
 */
@property (nonnull, nonatomic, readonly) NSURL *rly_cachesURL;

/**
 *  Returns a path to the file in `rly_documentsPath` with name `filename`.
 *
 *  @param filename The filename.
 */
-(nonnull NSString*)rly_documentsFileWithName:(nonnull NSString*)filename;

/**
 *  Returns `YES` if a directory exists at the specified path, otherwise `NO`.
 */
-(BOOL)rly_directoryExistsAtPath:(nonnull NSString*)path;

@end

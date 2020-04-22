//
//  CTMediator.m
//  CTMediator
//
//  Created by casa on 16/3/13.
//  Copyright © 2016年 casa. All rights reserved.
//

#import "CTMediator.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface CTMediator ()

@property (nonatomic, strong)NSMutableDictionary *cachedTarget;
@property (nonatomic, strong)Class PageNotFoundClass;

@end

@implementation CTMediator

#pragma mark - public methods
+ (instancetype)sharedInstance
{
    static CTMediator *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      mediator = [[CTMediator alloc] init];
      mediator.PageNotFoundClass = [mediator addPageNotFoundClass];
    });
    return mediator;
}

/*
 scheme://[target]/[action]?[params]
 
 url sample:
 aaa://targetA/actionB?id=1234
 */

- (id)performActionWithUrl:(NSURL *)url completion:(void (^)(NSDictionary *))completion
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *urlString = [url query];
    for (NSString *param in [urlString componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[elts lastObject] forKey:[elts firstObject]];
    }
    
    // 这里这么写主要是出于安全考虑，防止黑客通过远程方式调用本地模块。这里的做法足以应对绝大多数场景，如果要求更加严苛，也可以做更加复杂的安全逻辑。
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    // 这个demo针对URL的路由处理非常简单，就只是取对应的target名字和method名字，但这已经足以应对绝大部份需求。如果需要拓展，可以在这个方法调用之前加入完整的路由逻辑
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        } else {
            completion(nil);
        }
    }
    return result;
}

- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params shouldCacheTarget:(BOOL)shouldCacheTarget API_AVAILABLE(ios(6.0))
{    
    NSString *targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    NSString *actionString = [NSString stringWithFormat:@"Action_%@:", actionName];
    Class targetClass;
    
    NSObject *target = self.cachedTarget[targetClassString];
    if (target == nil) {
        targetClass = NSClassFromString(targetClassString);
        target = [[targetClass alloc] init];
    }
    
    SEL action = NSSelectorFromString(actionString);
    
    if (target == nil) {
      // 这里是处理无响应请求的地方之一，这个demo做得比较简单，如果没有可以响应的target，就直接return了。实际开发过程中是可以事先给一个固定的target专门用于在这个时候顶上，然后处理这种请求的
      return [self pageNotFound];
    }
    
    if (shouldCacheTarget) {
        self.cachedTarget[targetClassString] = target;
    }

    if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
    } else {
        // 有可能target是Swift对象
        actionString = [NSString stringWithFormat:@"Action_%@WithParams:", actionName];
        action = NSSelectorFromString(actionString);
        if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
        } else {
            // 这里是处理无响应请求的地方，如果无响应，则尝试调用对应target的notFound方法统一处理
            SEL action = NSSelectorFromString(@"notFound:");
            if ([target respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
            } else {
              // 这里也是处理无响应请求的地方，在notFound都没有的时候，这个demo是直接return了。实际开发过程中，可以用前面提到的固定的target顶上的。
              [self.cachedTarget removeObjectForKey:targetClassString];
              return [self pageNotFound];
            }
        }
    }
}

- (id)performTarget:(NSString *)targetName action:(NSString *)actionName shouldCacheTarget:(BOOL)shouldCacheTarget API_AVAILABLE(ios(6.0))
{
    NSString *targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    NSString *actionString = [NSString stringWithFormat:@"Action_%@", actionName];
    Class targetClass;
    
    NSObject *target = self.cachedTarget[targetClassString];
    if (target == nil)
    {
        targetClass = NSClassFromString(targetClassString);
        target = [[targetClass alloc] init];
    }
    
    SEL action = NSSelectorFromString(actionString);
    
    if (target == nil)
    {
      // 这里是处理无响应请求的地方之一，这个demo做得比较简单，如果没有可以响应的target，就直接return了。实际开发过程中是可以事先给一个固定的target专门用于在这个时候顶上，然后处理这种请求的
      return [self pageNotFound];
    }
    
    if (shouldCacheTarget)
    {
        self.cachedTarget[targetClassString] = target;
    }
    
    if ([target respondsToSelector:action])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [target performSelector:action withObject:nil];
#pragma clang diagnostic pop
    }
    else
    {
        // 有可能target是Swift对象
        actionString = [NSString stringWithFormat:@"Action_%@WithParams:", actionName];
        action = NSSelectorFromString(actionString);
        if ([target respondsToSelector:action])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            return [target performSelector:action withObject:nil];
#pragma clang diagnostic pop
        }
        else
        {
            // 这里是处理无响应请求的地方，如果无响应，则尝试调用对应target的notFound方法统一处理
            SEL action = NSSelectorFromString(@"notFound:");
            if ([target respondsToSelector:action])
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                return [target performSelector:action withObject:nil];
#pragma clang diagnostic pop
            }
            else
            {
              // 这里也是处理无响应请求的地方，在notFound都没有的时候，这个demo是直接return了。实际开发过程中，可以用前面提到的固定的target顶上的。
              [self.cachedTarget removeObjectForKey:targetClassString];
              return [self pageNotFound];
            }
        }
    }
}

- (void)releaseCachedTargetWithTargetName:(NSString *)targetName
{
    NSString *targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    [self.cachedTarget removeObjectForKey:targetClassString];
}

#pragma mark - getters and setters
- (NSMutableDictionary *)cachedTarget
{
    if (_cachedTarget == nil) {
        _cachedTarget = [[NSMutableDictionary alloc] init];
    }
    return _cachedTarget;
}

#pragma mark

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
  if(!sig)
  {
    return [self methodSignatureForSelector:@selector(pageNotFound)];
  }
  return sig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
  anInvocation.selector = @selector(pageNotFound);
  [anInvocation invoke];
  NSLog(@"forwardInvocation");
}

- (Class)addPageNotFoundClass {
  Class superClass = NSClassFromString(@"JgwBaseVC");
  Class classNew;
  if (superClass) {
    // 动态创建类，并继承自JgwBaseVC
    classNew = objc_allocateClassPair(superClass, "PageNotFoundVC", 0);
  } else {
    superClass = [UIViewController class];
    classNew = objc_allocateClassPair(superClass, "PageNotFoundVC", 0);
  }
  if (classNew) {
    // 添加方法
    class_addMethod(classNew, @selector(addMethodForMyClass), (IMP)addMethodForMyClass, "V@:");
    class_addMethod(classNew, @selector(methodSignatureForSelector:), (IMP)methodSignatureForSelector, "V@:");
    class_addMethod(classNew, @selector(forwardInvocation:), (IMP)forwardInvocation, "V@:");
  }
  return classNew;
}

- (UIViewController *)pageNotFound {
  id vc = [[self.PageNotFoundClass alloc] init];
  [vc addMethodForMyClass];
  return vc;
}

- (void)addMethodForMyClass {
}

static void addMethodForMyClass(id instance, SEL _cmd) {
//  // 获取类中指定名称实例成员变量的信息
//  Ivar ivar = class_getInstanceVariable([instance class], "view");
//  // 返回名为test的ivar变量的值
  UIView *view;
//  UIView *view = object_getIvar(instance, ivar);
  SEL viewSelector = NSSelectorFromString(@"view");
  if ([instance respondsToSelector:viewSelector]) {
    view = [instance view];
  }
  view.backgroundColor = [UIColor whiteColor];
  UILabel *l = [[UILabel alloc] initWithFrame:view.bounds];
  l.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  l.text = @"啊哦~功能页面不见了！";
  l.textAlignment = NSTextAlignmentCenter;
  [view addSubview:l];
}
static NSMethodSignature * methodSignatureForSelector(id self, SEL _cmd, SEL aSelector) {
  NSMethodSignature *sig = ((id(*)(id, SEL, SEL))objc_msgSendSuper)(self, @selector(methodSignatureForSelector:), aSelector);
  return sig;
}
static void forwardInvocation(id self, SEL _cmd, NSInvocation *anInvocation) {
}

@end

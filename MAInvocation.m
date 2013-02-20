#import "MAInvocation.h"

#import "MAInvocation-asm.h"


@implementation MAInvocation {
    NSMethodSignature *_sig;
    struct RawArguments _raw;
}

+ (NSInvocation *)invocationWithMethodSignature: (NSMethodSignature *)sig
{
    return [[[self alloc] initWithMethodSignature: sig] autorelease];
}

- (id)initWithMethodSignature: (NSMethodSignature *)sig
{
    if((self = [super init]))
    {
        _sig = [sig retain];
        
        NSUInteger argsCount = [sig numberOfArguments];
        if(argsCount > 6)
        {
            _raw.stackArgsCount = argsCount - 6;
            _raw.stackArgs = calloc(argsCount - 6, sizeof(*_raw.stackArgs));
        }
    }
    return self;
}

- (void)dealloc
{
    [_sig release];
    free(_raw.stackArgs);
    
    [super dealloc];
}

- (NSMethodSignature *)methodSignature
{
    return nil;
}

- (void)retainArguments
{
}

- (BOOL)argumentsRetained
{
    return YES;
}

- (id)target
{
    id target;
    [self getArgument: &target atIndex: 0];
    return target;
}

- (void)setTarget: (id)target
{
    [self setArgument: &target atIndex: 0];
}

- (SEL)selector
{
    SEL sel;
    [self getArgument: &sel atIndex: 1];
    return sel;
}

- (void)setSelector: (SEL)selector
{
    [self setArgument: &selector atIndex: 1];
}

- (void)getReturnValue: (void *)retLoc
{
}

- (void)setReturnValue: (void *)retLoc
{
}

- (void)getArgument: (void *)argumentLocation atIndex: (NSInteger)idx
{
    uint64_t *src = [self argumentPointerAtIndex: idx];
    
    if(src)
    {
        NSUInteger size = [self sizeAtIndex: idx];
        memcpy(argumentLocation, src, size);
    }
}

- (void)setArgument: (void *)argumentLocation atIndex: (NSInteger)idx
{
    uint64_t *dest = [self argumentPointerAtIndex: idx];
    
    if(dest)
    {
        NSUInteger size = [self sizeAtIndex: idx];
        memcpy(dest, argumentLocation, size);
    }
}

- (void)invoke
{
    [self invokeWithTarget: [self target]];
}

- (void)invokeWithTarget: (id)target
{
    _raw.fptr = [target methodForSelector: [self selector]];
    MAInvocationCall(&_raw);
}

#pragma mark Private

- (uint64_t *)argumentPointerAtIndex: (NSInteger)idx
{
    uint64_t *ptr = NULL;
    if(idx == 0)
        ptr = &_raw.rdi;
    if(idx == 1)
        ptr = &_raw.rsi;
    if(idx == 2)
        ptr = &_raw.rdx;
    if(idx == 3)
        ptr = &_raw.rcx;
    if(idx == 4)
        ptr = &_raw.r8;
    if(idx == 5)
        ptr = &_raw.r9;
    if(idx >= 6)
        ptr = _raw.stackArgs + idx - 6;
    return ptr;
}

- (NSUInteger)sizeAtIndex: (NSInteger)idx
{
    const char *type = [_sig getArgumentTypeAtIndex: idx];
    NSUInteger size;
    NSGetSizeAndAlignment(type, &size, NULL);
    return size;
}

void MAInvocationCall_disabled(struct RawArguments *r)
{
    void (*f)(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t) = r->fptr;
    f(r->rdi, r->rsi, r->rdx, r->rcx, r->r8, r->r9, r->stackArgs[0], r->stackArgs[1], r->stackArgs[2]);
    uint64_t stackArgs[r->stackArgsCount];
    for(uint64_t i = 0; i < r->stackArgsCount; i++)
        stackArgs[i] = r->stackArgs[i];
    r->fptr = stackArgs;
}

@end

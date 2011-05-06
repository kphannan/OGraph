//
//  GraphSearchAStar.m
//  GraphLib
//
//  Created by Matthew McGlincy on 5/3/11.
//  Copyright 2011 n/a. All rights reserved.
//

#import "GraphEdge.h"
#import "GraphNode.h"
#import "GraphSearchAStar.h"
#import "Heuristic.h"
#import "IndexedPriorityQLow.h"
#import "SparseGraph.h"

static NSNumber *kZero;

@interface GraphSearchAStar() 
- (void)search;
@end

@implementation GraphSearchAStar


@synthesize graph;

+ (void)initialize {
    static bool initialized = FALSE;
    if (!initialized) {
        kZero = [[NSNumber alloc] initWithUnsignedInteger:0U];
    }
}

- (id)initWithGraph:(SparseGraph *)aGraph
    sourceNodeIndex:(NSUInteger)aSourceNodeIndex    
    targetNodeIndex:(NSUInteger)aTargetNodeIndex 
    heuristic:(id<Heuristic>)aHeuristic {
    self = [super init];
    if (self) {
        self.graph = aGraph;
        sourceNodeIndex = aSourceNodeIndex;
        targetNodeIndex = aTargetNodeIndex;
        heuristic = aHeuristic;
        // TODO: use arrays?
        gCosts = [[NSMutableArray alloc] initWithCapacity:graph.numNodes];
        fCosts = [[NSMutableArray alloc] initWithCapacity:graph.numNodes];
        shortestPathTree = [[NSMutableArray alloc] initWithCapacity:graph.numNodes];
        searchFrontier = [[NSMutableArray alloc] initWithCapacity:graph.numNodes];
        for (int i = 0; i < graph.numNodes; i++) {
            [gCosts addObject:kZero];
            [fCosts addObject:kZero];
            [shortestPathTree addObject:kZero];
            [searchFrontier addObject:kZero];
        }
        // do the search
        [self search];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)search {
    // create an indexed priority queue of nodes.
    // The queue will give priority to nodes with low F costs (F=G+H)
    IndexedPriorityQLow *pq = [[IndexedPriorityQLow alloc] initWithKeys:fCosts
                                                                maxSize:graph.numNodes];
    
    // put the source node on the queue
    [pq insert:sourceNodeIndex];
    
    // while the queue is not empty
    while (![pq empty]) {
        // get the lowest cost node from the queue
        NSUInteger nextClosestNodeIndex = [pq pop];
        
        // move this edge from the search frontier to the shortest path tree
        [shortestPathTree replaceObjectAtIndex:nextClosestNodeIndex 
                                    withObject:[searchFrontier objectAtIndex:nextClosestNodeIndex]];
        
        // if the target has been found, exit
        if (nextClosestNodeIndex == targetNodeIndex) {
            return;
        }
        
        // now to relax the edges, 
        // for each edge connected to the next closest node.
        NSArray *edges = [graph getEdgesForNodeWithIndex:nextClosestNodeIndex];
        for (GraphEdge *edge in edges) {
            // calculate the heuristic cost from this node to the target (H)
            double hCost = [heuristic calculateWithGraph:graph 
                                              node1Index:targetNodeIndex 
                                              node2Index:edge.to];
            
            // calculate the "real" cost to this node from the source (G)
            double currentCost = [[gCosts objectAtIndex:nextClosestNodeIndex] doubleValue];
            double gCost = currentCost + edge.cost;

            // if the node has not been added to the frontier,
            // add it and update the G and F costs            
            if ([searchFrontier objectAtIndex:edge.to] == kZero) {
                [gCosts replaceObjectAtIndex:edge.to withObject:[NSNumber numberWithDouble:gCost]];
                [fCosts replaceObjectAtIndex:edge.to withObject:[NSNumber numberWithDouble:(gCost + hCost)]];
                [pq insert:edge.to];
                [searchFrontier replaceObjectAtIndex:edge.to withObject:edge];
            } 
            // if this node is already on the frontier but the cost to get here this 
            // way is cheaper than has been found previously, update the node costs
            // and frontier accordingly
            else if (gCost < [[gCosts objectAtIndex:edge.to] doubleValue] &&
                     [shortestPathTree objectAtIndex:edge.to] == kZero) {
                [gCosts replaceObjectAtIndex:edge.to withObject:[NSNumber numberWithDouble:gCost]];
                [fCosts replaceObjectAtIndex:edge.to withObject:[NSNumber numberWithDouble:(gCost + hCost)]];
                
                // because the cost is less than it was previously, the PQ must
                // be resorted to account for this.
                [pq changePriority:edge.to];
                
                [searchFrontier replaceObjectAtIndex:edge.to withObject:edge];
            }
        }
    }
}

- (NSArray *)getSPT {
    return shortestPathTree;
}

- (NSArray *)getPathToTarget {
    NSMutableArray *path = [[NSMutableArray alloc] init];
    
    //just return an empty path if no target or no path found
    //    if (targetNodeIndex < 0) {
    //        return path;
    //    }
    
    NSUInteger nd = targetNodeIndex;
    [path insertObject:[NSNumber numberWithUnsignedInt:nd] atIndex:0];
    
    while (nd != sourceNodeIndex && 
           [shortestPathTree objectAtIndex:nd] != kZero) {
        GraphEdge *edge = [shortestPathTree objectAtIndex:nd];
        nd = edge.from;
        [path insertObject:[NSNumber numberWithUnsignedInt:nd] atIndex:0];
    }
    
    return path;
}

- (double)getCostToNodeIndex:(NSUInteger)idx {
    return [[gCosts objectAtIndex:idx] doubleValue];    
}

- (double)getCostToTarget {
    return [self getCostToNodeIndex:targetNodeIndex];
}

@end


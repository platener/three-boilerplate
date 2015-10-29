THREE = require 'three'
$ = require 'jquery'
require 'meshlib'
Util = require './utilityFunctions'
Shape = require './shape'
EdgeLoop = require './edgeloop'

class ShapesFinder
  constructor: ->
    @shapes = []
    @drawable = new THREE.Object3D()

  nextVertexIndex: ( inIndex ) ->
    outIndex = inIndex + 1
    if outIndex > 2
      outIndex = 0
    return outIndex

  getEdges: (faces) ->
    edges = []
    for face in faces
      indexedFace = []
      for i in [0..2]
        j = @nextVertexIndex i
        edge = [face.vertices[i], face.vertices[j]]
        found = no
        for existingEdge, i in edges.slice()
          if Util.isSameEdge edge, existingEdge
            found = yes
            edges.splice(i, 1)
        if not found
          edges.push edge
    return edges

  mergeTwoEdges: (edge1, edge2) ->
    added = no
    newEdge = edge1
    if Util.isSameVec( edge2[edge2.length - 1], edge1[0] )
      newEdge = edge2
      newEdge = newEdge.concat(edge1[1..])
      added = true
    if not added and Util.isSameVec( edge1[edge1.length - 1], edge2[0] )
      newEdge = newEdge.concat(edge2[1..])
      added = true
    return { newEdge, added }

  mergeEdges: (inEdges) ->
    edges = [inEdges[0]]
    inEdges.splice(0, 1)
    merged = no
    for inEdge in inEdges
      added = no
      for edge, i in edges
        if not added
          addEdge = @mergeTwoEdges edge, inEdge
          edges[i] = addEdge.newEdge
          added = addEdge.added
      if not added
        edges.push inEdge
      else
        merged = yes
    return { edges, merged }

  getEdgeLoops: (edges) ->
    if edges.length is 0
      return []
    merged = yes
    while merged
      mergeEdges = @mergeEdges edges
      edges = mergeEdges.edges
      merged = mergeEdges.merged
    return edges

  findEdgeLoops: (faces) ->
    edges = @getEdges faces
    edgeLoops = @getEdgeLoops edges
    return edgeLoops

  findShapesFromModel: (model) ->
    shapes = []
    faces = model.model.getFaces()
    shape = @findEdgeLoops faces
    newEdgeLoops = []
    for edgeLoop in shape
      newEdgeLoop = new EdgeLoop(edgeLoop)
      newEdgeLoops.push newEdgeLoop
    shape = (new Shape(newEdgeLoops))
    shapes.push shape
    @shapes = shapes
    @setupDrawable()
    return shapes

  findShapesFromFaceSets: ( faceSets ) ->
    shapes = []
    for faceSet in faceSets
      shape = @findEdgeLoops faceSet
      shapes.push shape
    newShapes = []
    for shape in shapes
      newEdgeLoops = []
      for edgeLoop in shape
        newEdgeLoop = new EdgeLoop(edgeLoop)
        newEdgeLoops.push newEdgeLoop
      newShapes.push (new Shape(newEdgeLoops))
    @shapes = newShapes
    @setupDrawable()
    return newShapes

# coffeelint: disable=cyclomatic_complexity
  getColorFromIndex: ( index ) ->
    switch (index % 6)
      when 0 then lineColor = 0xff0000 #red
      when 1 then lineColor = 0x00ff00 #green
      when 2 then lineColor = 0x0000ff #blue
      when 3 then lineColor = 0xffff00 #yellow
      when 4 then lineColor = 0xff00ff #magenta
      when 5 then lineColor = 0x00ffff #cyan
    return lineColor
# coffeelint: enable=cyclomatic_complexity

  setupDrawable: ->
    while (@drawable.children.length > 0)
      @drawable.remove @drawable.children[0]
    for shape, i in @shapes
      lineColor = @getColorFromIndex i
      for edgeLoop in shape.getEdgeLoops()
        material =
          new THREE.LineDashedMaterial(
            { color: lineColor, dashSize: 0.1, gapSize: 0.3 })
        geometry = new THREE.Geometry()
        for vertex in edgeLoop.vertices
          v = new THREE.Vector3(vertex.x, vertex.y, vertex.z)
          geometry.vertices.push v
        geometry.computeLineDistances()
        obj = new THREE.Line( geometry, material )
        @drawable.add obj

  getDrawable: ->
    return @drawable


module.exports = ShapesFinder

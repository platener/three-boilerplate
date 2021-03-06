THREE = require 'three'

class HoleDetector

  constructor: ->
    @drawable = new THREE.Object3D()

  detectHoles: ( shapes ) ->
    @myShapes = shapes
    for shape in shapes
      shape.detectHoles()
    @setupDrawable()

  setupDrawable: ->
    while (@drawable.children.length > 0)
      @drawable.remove @drawable.childen[0]
    for shape in @myShapes
      for edgeLoop in shape.getEdgeLoops()
        geomToDraw = new THREE.Geometry()

        for vertex, vertexInd in edgeLoop.vertices
          geomToDraw.vertices.push( vertex )

          if vertexInd >= 2
            face = new THREE.Face3( 0, vertexInd - 1, vertexInd )
            geomToDraw.faces.push( face )

        material = new THREE.MeshBasicMaterial(
          color: if edgeLoop.hole then 0xff0000 else 0x00ff00,
          side: 2 )
        if edgeLoop.hole
          material.polygonOffset = true
          material.polygonOffsetFactor = -1
          material.polygonOffsetUnits = 0.00001
        mesh = new THREE.Mesh( geomToDraw, material )
        @drawable.add(mesh)

  getDrawable: ->
    return @drawable

module.exports = HoleDetector

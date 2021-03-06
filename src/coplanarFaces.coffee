THREE = require 'three'
meshlib = require 'meshlib'
Util = require './utilityFunctions'

class CoplanarFaces

  constructor: ->
    @drawable = new THREE.Object3D()
    @threshold = 0.00001
    @debug = false

  isCoplanar: (face1, face2) ->
    normal1 = new THREE.Vector3(face1.normal.x, face1.normal.y, face1.normal.z)
    normal2 = new THREE.Vector3(face2.normal.x, face2.normal.y, face2.normal.z)
    return normal1.angleTo(normal2) <= @threshold

  isAdjacent: (face1, face2) ->
    for index1 in [0..2]
      for index2 in [0..2]
        edge1 = [face1.vertices[index1], face1.vertices[(index1 + 1) % 3]]
        edge2 = [face2.vertices[index2], face2.vertices[(index2 + 1) % 3]]
        if Util.isSameEdge edge1, edge2
          return true
    return false

  isAdjacentAndCoplanar: (face1, face2) ->
    return @isAdjacent(face1, face2) and @isCoplanar(face1, face2)

  setDebug: (debug) ->
    @debug = debug

  setThreshold: (threshold) ->
    @threshold = threshold

  searchAdjacentCoplanarFaces: (face1, index1, planarModel) ->
    planarModel.push face1
    @faceUsed[index1] = true

    for face2, index2 in @faces when index1 isnt index2 and
        not @faceUsed[index2] and
        @isAdjacentAndCoplanar(face1, face2)
      @searchAdjacentCoplanarFaces face2, index2, planarModel

  findCoplanarFaces: (@model) ->

    @faces = @model.model.getFaces()

    if @debug
      console.log 'faces.length ' + @faces.length

    @planarModels = []
    @faceUsed = (false for [1..@faces.length])

    for face1, index1 in @faces when not @faceUsed[index1]
      if @debug
        console.log "New planarModel #{@planarModels.length + 1}" +
        " at face #{index1 + 1}/#{@faces.length}"
      @planarModels.push []
      @searchAdjacentCoplanarFaces face1, index1,
        @planarModels[@planarModels.length - 1]

    if @debug
      console.log 'planarModels.length ' + @planarModels.length

    return @planarModels

  setupDrawable: ->
    @drawable = new THREE.Object3D()

    for model in @planarModels
      geometry = new THREE.Geometry()
      for face in model
        for i in [0..2]
          geometry.vertices.push(new THREE.Vector3(
            face.vertices[i].x,
            face.vertices[i].y,
            face.vertices[i].z))
        len = geometry.vertices.length
        geometry.faces.push(new THREE.Face3(len - 3, len - 2, len - 1))
      mesh = new THREE.Mesh(geometry)
      @drawable.add mesh

  getDrawable: ->
    return @drawable


module.exports = CoplanarFaces

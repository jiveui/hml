package hml.xml.typeResolver;

import hml.xml.typeResolver.IHaxeTypeResolver;
import hml.base.MatchLevel;
import hml.xml.Data;

using hml.base.MacroTools;

class DefaultXMLDataRootParser extends DefaultXMLDataParser implements IXMLDataNodeParser<XMLData, Node, Type> {

    override public function match(data:XMLData, parent:Node):MatchLevel {
        return Std.is(data, XMLDataRoot) ? ClassLevel : None;
    }

    override function processSpecificNamespace(name:XMLQName, node:Node, ?child:Node, ?cData:String, pos:XMLDataPos):Bool {
        inline function data() return child != null ? child.cData : cData;

        var res = true;
        switch (node.model.resolveNamespace(name.ns)) {
            case DefaultXMLDataParser.HAXE_NAMESPACE:
                switch (name.name) {
                    case "Implements":
                        var type:Type = cast node;
                        var imps = data().stringToTypes();
                        if (type.implementsList == null)
                            type.implementsList = imps;
                        else
                            for (t in imps) type.implementsList.push(t);
                    case "Declarations" | "Private" | "Public":
                        var type:Type = cast node;
                        var publicAccess = name.name != "Private";
                        for (c in child.unresolvedNodes) {
                            c.publicAccess = publicAccess;
                            type.declarations.push(c);
                        }
                    case "Script":
                        var type:Type = cast node;
                        type.script = type.script == null ? data() : type.script + '\n' + data();
                    case _:
                        res = false;
                }
            case _:
                res = false;
        }

        return res ? res : super.processSpecificNamespace(name, node, child, cData, pos);
    }

    override public function parse(data:XMLData, parent:Node, parser:IXMLDataParser<XMLData, Node>):Type {
        var root:XMLDataRoot = cast data;

        var type = new Type();
        type.root = type;
        type.file = root.file;
        type.pos = root.pos;
        type.type = root.type;
        type.parent = null;

        parseNode(type, root, parser);

        type.id = "this";
        type.idSetted = true;

        return type;
    }
}

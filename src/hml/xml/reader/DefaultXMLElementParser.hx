package hml.xml.reader;

import hml.base.StringUtils;
import hml.base.StringUtils;
import hml.base.MatchLevel;
import hml.xml.reader.IXMLParser;
import com.tenderowls.xml176.Xml176Parser;

using hml.base.MatchLevel;
using hml.xml.Data;
using StringTools;

class DefaultXMLElementParser implements IXMLNodeParser<XMLData> {
    public function new() {}

    public function match(xml:Xml176Document, parent:XMLData):MatchLevel {
        return switch (xml.document.nodeType) {
            case Xml.Element: GlobalLevel;
            default: None;
        };
    }

    public function parse(node:Xml176Document, parent:XMLData, parser:IXMLParser<XMLData>):XMLData {
        return parseData(new XMLData(), node, parent, parser);
    }

    function posToXMLDataPos(xml:Xml176Document, pos:Pos):XMLDataPos {
        var raw = xml.rawData;
        inline function getLinePos(pos:Int) {
            var s = raw.substr(0, pos);
            var lines = StringUtils.splitLines(s);
            return {line:lines.length, pos:lines[lines.length - 1].length};
        }
        return {
            from: getLinePos(pos.from),
            to: getLinePos(pos.to),
            min: pos.from,
            max: pos.to,
            file: xml.path
        }
    }

    function parseData(res:XMLData, xmlNode:Xml176Document, parent:XMLData, parser:IXMLParser<XMLData>) {
        var node = xmlNode.document;
        res.name = node.nodeName.toXMLQName();
        res.nodePos = posToXMLDataPos(xmlNode, xmlNode.getNodePosition(node));
        res.parent = parent;
        res.root = parent != null ? parent.root : null;

        inline function formatNS(value:String) return if (value.endsWith(".*")) value.substr(0, -2) else value;

        for (a in node.attributes()) {
            var qName = a.toXMLQName();
            var value = node.get(a).htmlUnescape();
            switch ({name:qName.name, ns:qName.ns}) {
                case {name:"xmlns", ns:null}: res.namespaces["*"] = formatNS(value);
                case {name:n, ns:"xmlns"}: res.namespaces[n] = formatNS(value);
                case _:
                    res.attributes.set(qName, value);
                    res.attributesPos.set(qName, posToXMLDataPos(xmlNode, xmlNode.getAttrPosition(node, a)));
            }
        }

        var index = 0;
        for (c in node)
            switch (c.nodeType) {
                case Xml.PCData, Xml.CData:
                    var data = c.nodeValue.trim();
                    if (data.length > 0)
                        res.cData = res.cData == null ? data : res.cData + "\n" + data;

                default:
                    var node:XMLData = parser.parse(xmlNode.sub(c), res);
                    if (node != null) {
                        node.index = index++;
                        res.nodes.push(node);
                    }
            }

        return res;
    }
}
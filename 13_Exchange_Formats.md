# Exchange Formats

## Interchanging Incomplete Models

It is common for **DMN** models to be interchanged before they are complete. This occurs frequently when doing iterative modeling, where one user (such as a knowledge source expert or business user) first defines a high-level model and then passes it on to another person to complete or refine the model.

Such "incomplete" models are ones in which not all of the mandatory model attributes have been filled in yet or the cardinality of the lower bound of attributes and associations has not been satisfied.

XMI allows for the interchange of such incomplete models. In **DMN**, we extend this capability to interchange of XML files based on the **DMN** XML-Schema. In such XML files, implementers are expected to support this interchange by:

- Disregarding missing attributes that are marked as "required" in the **DMN** XML-Schema.

- Reducing the lower bound of elements with "minOccurs" greater than 0.

## Machine Readable Files

All machine-readable files, including XSD, XMI and XML files, can be found at <https://www.omg.org/spec/DMN>.

- For the **DMN** XMI Model, the main file is DMN.xmi.

- For the **DMN** XSD Interchange (supporting Conformance Levels 1, 2 and 3), the main file is DMN.xsd.

- XML serializations of the examples in [DMN Examples](12_DMN_Examples.md#dmn-examples) are provided as a non-normative zip file.

## XSD

### Document Structure

A domain-specific set of model elements is interchanged in one or more **DMN** files. The root element of each file SHALL be \<DMN**:** Definitions\>. The set of files SHALL be self-contained, i.e., all definitions that are used in a file SHALL be imported directly or indirectly using the \<DMN**:** Import\> element.

Each file SHALL declare a “name space” that MAY differ between multiple files of one model.

**DMN** files MAY import non-**DMN** files (such as XSDs and PMMLs) if the contained elements use external definitions.

Starting from DMN 1.7, the XML namespace URIs for backwards-compatible 1.x versions of DMN are fixed at:

- <https://www.omg.org/spec/DMN/> for the semantic model

- <https://www.omg.org/spec/DMN/DMNDI/> for the diagram interchange model

- <https://www.omg.org/spec/DMN/FEEL/> for the FEEL expression language

- <https://www.omg.org/spec/DMN/B-FEEL/> for the B-FEEL expression language

The \<dmn:definitions\> root element of a DMN XML file MUST indicate the concrete DMN version that is used in the file by setting the dmnVersion attribute, e.g.:

    <dmn:definitions dmnVersion="1.7" ...

In addition, the \<dmn:definitions\> root element SHOULD include an xsi:schemaLocation attribute that points to the XML schema files for all namespaces, i.e. the URLs of the XSDs that are publicly hosted by OMG without dated version stamps, e.g.

    <dmn:definitions dmnVersion="1.7" ...
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="
    https://www.omg.org/spec/DMN/
    https://www.omg.org/spec/DMN/DMN.xsd
    https://www.omg.org/spec/DMN/DMNDI/
    https://www.omg.org/spec/DMN/DMNDI.xsd
    https://www.omg.org/spec/SCE/DI/
    https://www.omg.org/spec/SCE/DI.xsd
    https://www.omg.org/spec/SCE/DC/
    https://www.omg.org/spec/SCE/DC.xsd
    ">

### References within the DMN XSD

Many **DMN** elements that may need to be referenced contain IDs and within the **BPMN** XSD, references to elements are expressed via these IDs. The XSD IDREF type is the traditional mechanism for referencing by IDs, however it can only reference an element within the same file. **DMN** elements of type DMNElementReference support referencing by ID, across files, by utilizing an href attribute whose value must be a valid URI reference \[RFC 3986\] where the path components may be absolute, the reference has no query component, and the fragment consists of the value of the id of the referenced **DMN** element.

For example, consider the following Decision:

\<decision name="Pre-Bureau Risk Category" id="prebureauriskDec01"\>...\</decision\>

When this Decision is referenced, e.g., by an InformationRequirement in a Decision that is defined in another file, the reference could take the following form:  
\<requiredDecision href=”<http://www.example.org/Definitions01#prebureauriskDec01>”/\>  
where “<http://www.example.org/Definitions01>” is a URI representing the namespace of the model specified in the DMN file. When the Decision is referenced in the same file, the reference could take both of the following forms: \<requiredDecision href=”http://www.example.org/Definitions01.xml#prebureauriskDec01”/\> or \<requiredDecision href=”#prebureauriskDec01”/\>

Notice that the **BPMN** processes and tasks that use a decision are referenced using the href attribute as well:

indeed, it is compatible with the system to reference external Process and Task instances in **BPMN 2.0** Definitions, which is also based on IDs.

Attribute typeRef references ItemDefinitions and built-in types by name not ID. In order to support imported types, typeRef uses the namespace-qualified name syntax \[qualifer\].\[local-name\], where qualifier is specified by the name attribute of the Import element for the imported type. If the referenced type is not imported, the prefix SHALL be omitted.

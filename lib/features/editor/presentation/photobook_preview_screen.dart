import 'package:flutter/material.dart';

import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import 'photobook_editor_screen.dart';

class PhotobookPreviewScreen extends StatefulWidget {
  const PhotobookPreviewScreen({super.key, required this.design, required this.schema, required this.photoStateByFrameId, required this.editedTextById, this.onBackToEdit, this.onContinueCheckout});
  final PhotobookDesignModel design; final DesignSchemaModel schema; final Map<String, FramePhotoState> photoStateByFrameId; final Map<String, String> editedTextById; final VoidCallback? onBackToEdit; final VoidCallback? onContinueCheckout;
  @override State<PhotobookPreviewScreen> createState()=>_PhotobookPreviewScreenState();
}

class _PhotobookPreviewScreenState extends State<PhotobookPreviewScreen>{ int selected=0;
  @override Widget build(BuildContext context){
    final pages=widget.schema.pages;
    final page=pages[selected];
    final bg=(page.previewUrl?.isNotEmpty==true?page.previewUrl:page.backgroundUrl?.isNotEmpty==true?page.backgroundUrl:page.editorBackgroundUrl?.isNotEmpty==true?page.editorBackgroundUrl:page.cleanBackgroundUrl);
    return Scaffold(appBar: AppBar(title: const Text('Pratinjau Desain')),
      body: SafeArea(child: Column(children:[
        Expanded(child: OrientationBuilder(builder:(c,o)=>Center(child:AspectRatio(aspectRatio:o==Orientation.landscape?1.9:1.4, child:Container(margin:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)),clipBehavior:Clip.antiAlias,child:Stack(children:[Positioned.fill(child:bg==null?const Center(child:Icon(Icons.image_not_supported)):Image.network(bg,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image))), ..._editedTextOverlays(page)]))))),
        SizedBox(height:88, child:ListView.separated(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:pages.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i)=>GestureDetector(onTap:()=>setState(()=>selected=i),child:Container(width:96,padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:i==selected?const Color(0xFF168CA0):Colors.white,borderRadius:BorderRadius.circular(12)),child:Center(child:Text('Hal. ${pages[i].pageNumber}',style:TextStyle(color:i==selected?Colors.white:Colors.black87))))))),
        Padding(padding: const EdgeInsets.all(12), child: Row(children:[Expanded(child:OutlinedButton(onPressed:widget.onBackToEdit ?? ()=>Navigator.pop(context), child:const Text('Pratinjau'))), const SizedBox(width:10), Expanded(child:ElevatedButton(onPressed:widget.onContinueCheckout, child:const Text('Lanjut Checkout')))]))
      ])));
  }

  List<Widget> _editedTextOverlays(DesignPageModel page){
    final out=<Widget>[];
    for(final layer in page.layers){
      final value=widget.editedTextById[layer.id];
      if(value==null||value.trim().isEmpty) continue;
      out.add(Positioned(left: layer.x.toDouble(), top: layer.y.toDouble(), child: Text(value, style: const TextStyle(fontSize: 12,color: Colors.black))));
    }
    return out;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leafcare_ia/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('La pantalla de login se renderiza', (tester) async {
    await tester.pumpWidget(const LeafCareApp());

    expect(find.text('LeafCare AI'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsWidgets);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}

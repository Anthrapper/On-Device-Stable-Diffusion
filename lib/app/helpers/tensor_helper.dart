import 'dart:math';

typedef Tensor4dInt = List<List<List<List<int>>>>;
typedef Tensor3dInt = List<List<List<int>>>;
typedef Tensor4dFloat = List<List<List<List<double>>>>;
typedef Tensor3dFloat = List<List<List<double>>>;

Tensor3dFloat outputToTensor3d(List<dynamic> outputDataDynamic) {
  final Tensor3dFloat outputData = [];
  for (final innerList1 in outputDataDynamic) {
    final List<List<double>> innerList2 = [];
    for (final innerList3 in innerList1 as Iterable<dynamic>) {
      final List<double> convertedList =
          (innerList3 as List<dynamic>).cast<double>().toList();
      innerList2.add(convertedList);
    }
    outputData.add(innerList2);
  }
  return outputData;
}

Tensor4dInt outputToTensor4d(List<dynamic> outputDataDynamic) {
  final Tensor4dInt outputData = [];
  for (final innerList1 in outputDataDynamic) {
    final List<List<List<int>>> innerList2 = [];
    for (final innerList3 in innerList1 as Iterable<dynamic>) {
      final List<List<int>> innerList4 = [];
      for (final innerList5 in innerList3 as Iterable<dynamic>) {
        final List<int> convertedList = (innerList5 as List<dynamic>)
            .map<int>(
              (dynamic value) => value as int,
            )
            .toList();
        innerList4.add(convertedList);
      }
      innerList2.add(innerList4);
    }
    outputData.add(innerList2);
  }
  return outputData;
}

Tensor4dFloat outputToTensor4dFloat(List<dynamic> outputDataDynamic) {
  final Tensor4dFloat outputData = [];
  for (final innerList1 in outputDataDynamic) {
    final Tensor3dFloat innerList2 = [];
    for (final innerList3 in innerList1 as Iterable<dynamic>) {
      final List<List<double>> innerList4 = [];
      for (final innerList5 in innerList3 as Iterable<dynamic>) {
        final List<double> convertedList = (innerList5 as List<dynamic>)
            .map<double>((dynamic value) => (value as num).toDouble())
            .toList();
        innerList4.add(convertedList);
      }
      innerList2.add(innerList4);
    }
    outputData.add(innerList2);
  }
  return outputData;
}

Tensor4dFloat calculatePredX0(
  Tensor4dFloat latent,
  double aT,
  Tensor4dFloat latentPrev,
) {
  return List.generate(latentPrev.length, (i) {
    return List.generate(latentPrev[i].length, (j) {
      return List.generate(latentPrev[i][j].length, (k) {
        return List.generate(latentPrev[i][j][k].length, (l) {
          final double element =
              (latentPrev[i][j][k][l] - sqrt(1 - aT) * latent[i][j][k][l]) /
                  sqrt(aT);
          return element;
        });
      });
    });
  });
}

Tensor4dFloat latentMul(
  Tensor4dFloat latent,
  Tensor4dFloat unconditionalLatent,
  double unconditionalGuidanceScale,
) {
  for (int i = 0; i < latent.length; i++) {
    for (int j = 0; j < latent[i].length; j++) {
      for (int k = 0; k < latent[i][j].length; k++) {
        for (int l = 0; l < latent[i][j][k].length; l++) {
          latent[i][j][k][l] = unconditionalLatent[i][j][k][l] +
              unconditionalGuidanceScale *
                  (latent[i][j][k][l] - unconditionalLatent[i][j][k][l]);
        }
      }
    }
  }
  return latent;
}

Tensor4dFloat calculateUpdatedLatent(
  Tensor4dFloat latent,
  double aPrev,
  Tensor4dFloat predX0,
) {
  return List.generate(latent.length, (i) {
    return List.generate(latent[i].length, (j) {
      return List.generate(latent[i][j].length, (k) {
        return List.generate(latent[i][j][k].length, (l) {
          final double element = latent[i][j][k][l] * sqrt(1.0 - aPrev) +
              sqrt(aPrev) * predX0[i][j][k][l];
          return element;
        });
      });
    });
  });
}
// List<int> getShape(dynamic element) {
//   if (element is List) {
//     final shape = [element.length];
//     if (element.isNotEmpty) {
//       final innerShape = getShape(element.first);
//       shape.addAll(innerShape);
//     }
//     return shape;
//   } else {
//     return [];
//   }
// }

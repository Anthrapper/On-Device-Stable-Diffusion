package com.example.flutter_diffusion;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtException;
import ai.onnxruntime.OrtSession;

public class ONNXProcessor {
    public static List<List<List<List<Double>>>> decodeImg(List<List<List<List<Double>>>> inputData, byte[] modelPath) {
        try {
            float[][][][] sampleInput = convertToFloatArray(inputData);
            OrtEnvironment ortEnvironment = OrtEnvironment.getEnvironment();
            OrtSession session = ortEnvironment.createSession(modelPath);
            String inputName = session.getInputNames().iterator().next();
            OnnxTensor inputTensor = OnnxTensor.createTensor(ortEnvironment, sampleInput);
            Map<String, OnnxTensor> inputs = Collections.singletonMap(inputName, inputTensor);
            OrtSession.Result output = session.run(inputs);
            Object outputValue = output.get(0).getValue();
            if (outputValue instanceof float[][][][]) {
                float[][][][] decodedValue = (float[][][][]) outputValue;
                List<List<List<List<Double>>>> decodedImg = convertToDoubleList(decodedValue);
                output.close();
                session.close();
                ortEnvironment.close();
                return decodedImg;
            }
        } catch (OrtException e) {
            throw new RuntimeException(e);
        }
        return inputData;
    }

    private static float[][][][] convertToFloatArray(List<List<List<List<Double>>>> inputData) {
        if (inputData == null) {
            return new float[0][][][];
        }

        float[][][][] result = new float[inputData.size()][][][];
        for (int i = 0; i < inputData.size(); i++) {
            List<List<List<Double>>> array3D = inputData.get(i);
            result[i] = new float[array3D.size()][][];
            for (int j = 0; j < array3D.size(); j++) {
                List<List<Double>> array2D = array3D.get(j);
                result[i][j] = new float[array2D.size()][];
                for (int k = 0; k < array2D.size(); k++) {
                    List<Double> array1D = array2D.get(k);
                    result[i][j][k] = new float[array1D.size()];
                    for (int l = 0; l < array1D.size(); l++) {
                        result[i][j][k][l] = array1D.get(l).floatValue();
                    }
                }
            }
        }
        return result;
    }
    private static List<List<List<List<Double>>>> convertToDoubleList(float[][][][] inputData) {
        if (inputData == null) {
            return new ArrayList<>();
        }

        List<List<List<List<Double>>>> result = new ArrayList<>();
        for (float[][][] array3D : inputData) {
            List<List<List<Double>>> list3D = new ArrayList<>();
            for (float[][] array2D : array3D) {
                List<List<Double>> list2D = new ArrayList<>();
                for (float[] array1D : array2D) {
                    List<Double> list1D = new ArrayList<>();
                    for (float v : array1D) {
                        list1D.add((double) v);
                    }
                    list2D.add(list1D);
                }
                list3D.add(list2D);
            }
            result.add(list3D);
        }
        return result;
    }

}

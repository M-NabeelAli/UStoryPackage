

import Foundation
public class ApiManager {
    
    var baseURL = "https://api.spoonacular.com/"
    static public var shared = ApiManager()
    private var request: URLRequest?
    init () {}
    
    private func createGetRequestWithURLComponents(url:URL,
                                                   parameters: [String:Any],
                                                   requestType: RequestType) -> URLRequest? {
        var components = URLComponents(string: url.absoluteString)!
        components.queryItems = parameters.map { (key, value) in
            URLQueryItem(name: key, value: "\(value)")
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        request = URLRequest(url: components.url ?? url)
        request?.httpMethod = requestType.rawValue
        return request
    }
    
    private func createPostRequestWithBody(url:URL, parameters: [String:Any], requestType: RequestType) -> URLRequest? {
        request = URLRequest(url: url)
        request?.httpMethod = requestType.rawValue
        request?.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request?.addValue("application/json", forHTTPHeaderField: "Accept")
        if let requestBody = getParameterBody(with: parameters) {
            request?.httpBody = requestBody
        }
        request?.httpMethod = requestType.rawValue
        return request
    }
    
    private func getParameterBody(with parameters: [String:Any]) -> Data? {
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) else {
            return nil
        }
        return httpBody
    }
    
    private func createRequest(with url: URL, requestType: RequestType, parameters: [String: Any]) -> URLRequest? {
        if requestType == .getRequest {
            return createGetRequestWithURLComponents(url: url,
                                                     parameters: parameters,
                                                     requestType: requestType)
        }
        else {
            return createPostRequestWithBody(url: url,
                                             parameters: parameters,
                                             requestType: requestType)
        }
    }
    
   public func sendRequest<T:Codable>(model: T.Type,
                                with endpoint: Endpoint,
                                requestType: RequestType,
                                parameters: [String:Any],
                                completion: @escaping (Result<T, Error>) -> ()) {
        let url = URL(string: baseURL+endpoint.rawValue)!
        guard let urlRequest = createRequest(with: url,
                                             requestType: requestType,
                                             parameters: parameters) else { return }
        
        URLSession.shared.dataTask(with: urlRequest) { _data, response, error in
            do {
                let model = try JSONDecoder().decode(model.self, from: _data!)
                completion(.success(model))
            }
            catch {
                completion(.failure(error))
            }
            
        }
    }
}

public enum RequestType: String {
    case postRequest = "POST"
    case getRequest = "GET"
}

public enum Endpoint: String {
    case getProducts = "get/products"
}

